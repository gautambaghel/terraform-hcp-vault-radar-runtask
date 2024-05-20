# terraform-hcp-vault-radar-runtask

This repository contains the Terraform and python code for the Terraforn [run tasks](https://developer.hashicorp.com/terraform/cloud-docs/integrations/run-tasks) integration between [HashiCorp Vault Radar](https://developer.hashicorp.com/hcp/docs/vault-radar) and [HCP Terraform](https://app.terraform.io/public/signup/account)

## Introduction

The intention of this integration is to make sure that when DevOps engineers are creating Terraform runs they're not accidentally commiting their secrets, API keys, private keys and other sensitive information as part of their Terraform run.

The repository is setup as a typical Terraform module structure, here's the folder breakdown:

- `(root) folder`: The Terraform files for creating ECS task, service & Application load balancer for run task, it also contains the Dockerfile to build the Docker image with python code.
  - `(app) folder`: The folder containing the python code that creates a flask app and intercepts the API requests from HCP Terraform.
  - `(examples/basic) folder`: The Terraform files for deploying the root module, showing examples on how to create the VPC, ECS cluster, Cloudwatch, HCP Terraform run task & workspace.
    - `(sample) folder`: Containers a dummy Terraform configuration with an API key that can be picked up by Vault Radar, this is used to create a workspace in HCP Terraform and attach the run task

## Getting started

```sh
cd examples/basic
terraform init
terraform plan
terraform apply
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.47.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 0.24.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.47.0 |

## Resources

| Name | Type |
|------|------|
| [aws_ecs_service.hcp_vault_radar](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.hcp_vault_radar](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_role.ecs_task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ecs_task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.radar_init_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.ecs_task_execution_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ecs_task_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lb.hcp_vault_radar](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.hcp_vault_radar](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.hcp_vault_radar](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_security_group.hcp_vault_radar](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.allow_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.allow_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ssm_parameter.hcp_client_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.hcp_client_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.hcp_project_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#input\_cloudwatch\_log\_group\_arn) | The ARN of the CloudWatch log group where agent logs will be sent. | `string` | n/a | yes |
| <a name="input_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#input\_cloudwatch\_log\_group\_name) | The name of the CloudWatch log group where agent logs will be sent. | `string` | n/a | yes |
| <a name="input_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#input\_ecs\_cluster\_arn) | ARN of the ECS cluster where the agent will be deployed. | `string` | n/a | yes |
| <a name="input_hcp_client_id"></a> [hcp\_client\_id](#input\_hcp\_client\_id) | The client ID for the HCP project. | `string` | n/a | yes |
| <a name="input_hcp_client_secret"></a> [hcp\_client\_secret](#input\_hcp\_client\_secret) | The client secret for the HCP project. | `string` | n/a | yes |
| <a name="input_hcp_project_id"></a> [hcp\_project\_id](#input\_hcp\_project\_id) | The ID of the HCP project to use. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | A name to apply to resources. The name must be unique within an AWS account. | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | IDs of the subnet(s) where agents can be deployed (public subnets required) | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC where the cluster is running. | `string` | n/a | yes |
| <a name="input_ecs_cpu"></a> [ecs\_cpu](#input\_ecs\_cpu) | The CPU units allocated to the agent container(s). See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html#fargate-tasks-size | `number` | `512` | no |
| <a name="input_ecs_desired_count"></a> [ecs\_desired\_count](#input\_ecs\_desired\_count) | The number of agent containers to run. | `number` | `1` | no |
| <a name="input_ecs_memory"></a> [ecs\_memory](#input\_ecs\_memory) | The amount of memory, in MB, allocated to the agent container(s). | `number` | `1024` | no |
| <a name="input_extra_env_vars"></a> [extra\_env\_vars](#input\_extra\_env\_vars) | Extra environment variables to pass to the agent container. | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | `[]` | no |
| <a name="input_radar_cidr_blocks"></a> [radar\_cidr\_blocks](#input\_radar\_cidr\_blocks) | CIDR blocks to allow the agent to communicate with the HCP Vault Radar. | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_radar_egress_ports"></a> [radar\_egress\_ports](#input\_radar\_egress\_ports) | Egress ports to allow the agent to communicate with the HCP Vault Radar. | `set(string)` | <pre>[<br>  "0"<br>]</pre> | no |
| <a name="input_radar_ingress_ports"></a> [radar\_ingress\_ports](#input\_radar\_ingress\_ports) | Ingress ports to allow the agent to communicate with the HCP Vault Radar. | `set(string)` | <pre>[<br>  "80"<br>]</pre> | no |
| <a name="input_radar_runtask_image"></a> [radar\_runtask\_image](#input\_radar\_runtask\_image) | The Docker image with Terraform runtask server & Radar installed. | `string` | `"baghelg/hcp-radar-runtask:latest"` | no |
| <a name="input_task_policy_arns"></a> [task\_policy\_arns](#input\_task\_policy\_arns) | ARN(s) of IAM policies to attach to the agent task. Determines what actions the agent can take without requiring additional AWS credentials. | `list(string)` | `[]` | no |
| <a name="input_use_spot_instances"></a> [use\_spot\_instances](#input\_use\_spot\_instances) | Whether to use Fargate Spot instances. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_runtask_url"></a> [runtask\_url](#output\_runtask\_url) | The URL of the HTTP API for the HCP Vault Radar run task |
<!-- END_TF_DOCS -->
