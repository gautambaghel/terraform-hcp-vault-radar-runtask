import subprocess
import requests
import hashlib
import tarfile
import hmac
import json
import os

from flask import Flask, request
import tarfile
import csv
import time

app = Flask(__name__)
port = int(os.environ.get("PORT", 5000))

# Set the environment variables, HCP_CLIENT_ID, HCP_CLIENT_SECRET, HCP_PROJECT_ID
env_vars = os.environ.copy()

def send_callback(callback_url, access_token, status, message, results, url):
    # Format the payload for the callback
    # Schema Documentation - https://www.terraform.io/cloud-docs/api-docs/run-tasks-integration#request-body-1
    data = json.dumps(
        {
            "data": {
                "type": "task-results",
                "attributes": {
                    "status": status,
                    "message": message,
                    "url": url,
                },
                "relationships": {
                    "outcomes": {
                        "data": results,
                    }
                },
            }
        },
        separators=(",", ":"),
        indent=4,
    )

    options = {
        "method": "PATCH",
        "headers": {
            "Content-Type": "application/vnd.api+json",
            "Authorization": "Bearer " + access_token,
        },
        "data": data,
    }

    print(data)
    response = requests.patch(
        callback_url, headers=options["headers"], data=options["data"]
    ).json()
    print(json.dumps(response, separators=(",", ":"), indent=4))


def get_plan(url, access_token):
    headers = {"Authorization": "Bearer " + access_token}
    response = requests.get(url, headers=headers)
    plan = response.json()
    return plan


def download_config(configuration_version_download_url, access_token):
    headers = {
        "Content-Type": "application/vnd.api+json",
        "Authorization": "Bearer " + access_token,
    }
    response = requests.get(configuration_version_download_url, headers=headers)

    config_file = os.path.join(os.getcwd(), "pre_plan", "config.tar.gz")
    os.makedirs(os.path.dirname(config_file), exist_ok=True)
    with open(config_file, "wb") as file:
        file.write(response.content)

    with tarfile.open(config_file, "r:gz") as tar:
        tar.extractall(path="pre_plan")

    os.remove(config_file)

    # Somehow the scan.csv file is being added, so we need to remove it
    extra_file = os.path.join(os.getcwd(), "pre_plan", "scan.csv")
    os.remove(extra_file)


def validate_hmac(request):
    hmac_key = os.environ.get("HMAC_KEY", "abc123")
    # computed_hmac = hashlib.sha512(json.dumps(request.json).encode()).hexdigest()
    request_json = json.dumps(request.json, separators=(",", ":"))
    computed_hmac = hmac.new(
        hmac_key.encode(), request_json.encode(), hashlib.sha512
    ).hexdigest()
    remote_hmac = request.headers.get("x-tfc-task-signature")
    # If the HMAC validation fails, log the error and send an HTTP Status Code 401, Unauthorized
    # Currently undocumented but 401 is the expected response for an invalid HMAC
    if computed_hmac != remote_hmac:
        print(
            f"HMAC validation failed.\nExpected {remote_hmac}\nComputed {computed_hmac}"
        )
        return "", 401


def get_error_level(severity):
    severity = severity.lower()
    if severity == "low":
        return {"label": "Low", "level": "info"}
    elif severity == "medium":
        return {"label": "Medium", "level": "warning"}
    elif severity == "high":
        return {"label": "High", "level": "error"}
    elif severity == "critical":
        return {"label": "Critical", "level": "error"}
    else:
        return {"label": severity, "level": "none"}


def process_radar_output(result_path):
    results = []
    status = "passed"
    issues_count = 0
    message = "HashiCorp Vault Radar scan complete, no secrets found!"

    with open(result_path, "r") as file:
        radar_output = csv.reader(file)

        for row in radar_output:
            # Skip the header row
            if issues_count == 0:
                issues_count += 1
                continue

            issues_count += 1
            message = (
                f"HashiCorp Vault Radar scan complete, {issues_count} secrets found!"
            )
            error_level = get_error_level(row[4])
            tags = []
            for tag in row[12].split(" "):
                tags.append({"label": tag})
            result = json.dumps(
                {
                    "type": "task-result-outcomes",
                    "attributes": {
                        "outcome-id": f"vault-radar-{row[8]}",
                        "description": f"{row[1]} type secret found",
                        "tags": {
                            "status": [
                                {"label": f"{row[11]}", "level": error_level["level"]}
                            ],
                            "severity": [
                                {
                                    "label": error_level["label"],
                                    "level": error_level["level"],
                                }
                            ],
                            "tags": tags,
                        },
                        "body": f"""{row[1]} type secret found in `{row[7]}` with severity **{row[4]}**\n\n## Details\n\n* **Category**: {row[0]}\n* **Description**: {row[1]}\n* **Created at**: {row[2]}\n* **Author**: {row[3]}\n* **Severity**: {row[4]}\n* **Deep Link**: {row[6]}\n* **Path**: {row[7]}\n* **Value hash**: `{row[8]}`\n* **Fingerprint**: `{row[9]}`\n* **Textual Context**: `{row[10]}`\n* **Activeness**: {row[11]}\n* **Tags**: {row[12]}""",
                        "url": "https://vault-radar-portal.cloud.hashicorp.com",
                    },
                },
                separators=(",", ":"),
            )
            results.append(json.loads(result))

            if row[4] == "info" or row[4] == "medium" or row[4] == "high" or row[4] == "critical":
                status = "failed"

        return status, message, results

@app.route("/health", methods=["GET"])
def handle_health():
    return {"status": "healthy"}, 200

@app.route("/", methods=["POST"])
def handle_post():
    # Configure Flask middleware to parse the JSON body and validate the HMAC
    validate_hmac(request)

    # When a user adds a new Run Task to their Terraform Cloud organization, Terraform Cloud will attempt to
    # validate the Run Task address and HMAC by sending a payload with dummy data. This condition will have to be accounted for.
    if request.json["access_token"] != "test-token":

        # Segment Run Tasks based on stage
        if request.json["stage"] == "pre_plan":

            # Download the config files locally
            # API Documentation - https://www.terraform.io/cloud-docs/api-docs/configuration-versions#download-configuration-files
            configuration_version_download_url = request.json[
                "configuration_version_download_url"
            ]
            access_token = request.json["access_token"]
            organization_name = request.json["organization_name"]
            workspace_name = request.json["workspace_name"]
            run_id = request.json["run_id"]
            task_result_callback_url = request.json["task_result_callback_url"]

            # Download the config to a folder
            download_config(configuration_version_download_url, access_token)
            print(
                f"Config downloaded for Workspace: {organization_name}/{workspace_name}, Run: {run_id}\n downloaded at {os.getcwd()}/config"
            )

            # Run HashiCorp Vault Radar
            scan_folder = f"{os.getcwd()}/pre_plan"
            radar_output = f"{scan_folder}/vault-radar-output.csv"
            subprocess.run(
                [
                    "vault-radar",
                    "scan",
                    "folder",
                    "--outfile",
                    radar_output,
                    "--path",
                    scan_folder,
                ],
                env=env_vars,
            )
            status, message, results = process_radar_output(result_path=radar_output)

            # Send the results back to Terraform Cloud
            send_callback(
                callback_url=task_result_callback_url,
                access_token=access_token,
                status=status,
                message=message,
                results=results,
                url="https://vault-radar-portal.cloud.hashicorp.com",
            )
            return "pre plan run task passed", 200

        elif request.json["stage"] == "post_plan":

            # Do some processing on the Run Task request
            # Schema Documentation - https://www.terraform.io/cloud-docs/api-docs/run-tasks-integration#request-json
            plan_json_api_url = request.json["plan_json_api_url"]
            access_token = request.json["access_token"]
            organization_name = request.json["organization_name"]
            workspace_id = request.json["workspace_id"]
            run_id = request.json["run_id"]
            task_result_callback_url = request.json["task_result_callback_url"]
            plan_json = get_plan(plan_json_api_url, access_token)

            # Download the plan JSON to a file
            plan_file = os.path.join(os.getcwd(), "post_plan", "plan.json")
            os.makedirs(os.path.dirname(plan_file), exist_ok=True)
            with open(plan_file, "w") as file:
                json.dump(plan_json, file, indent=2)
            print(
                f"Plan downloaded for Workspace: {organization_name}/{workspace_id}, Run: {run_id}\n downloaded at {plan_file}"
            )

            # Run HashiCorp Vault Radar
            radar_output = f"{os.getcwd()}/post_plan/vault-radar-output.csv"
            subprocess.run(
                [
                    "vault-radar",
                    "scan",
                    "file",
                    "--outfile",
                    radar_output,
                    "--path",
                    plan_file,
                ],
                env=env_vars,
            )
            status, message, results = process_radar_output(result_path=radar_output)

            # Send the results back to Terraform Cloud
            send_callback(
                callback_url=task_result_callback_url,
                access_token=access_token,
                status=status,
                message=message,
                results=results,
                url="https://vault-radar-portal.cloud.hashicorp.com",
            )
            return "post plan run task passed", 200
    else:
        # Send a 200 to tell Terraform Cloud that we received the Run Task
        # Documentation - https://www.terraform.io/cloud-docs/api-docs/run-tasks-integration#run-task-request
        return "", 200


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=port)
