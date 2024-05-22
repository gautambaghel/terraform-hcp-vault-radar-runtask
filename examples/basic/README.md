<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.47.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 0.24.0 |
| <a name="requirement_tfe"></a> [tfe](#requirement\_tfe) | >= 0.55.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.47.0 |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_tfe"></a> [tfe](#provider\_tfe) | >= 0.55.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [local_file.template_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [tfe_organization_run_task.hcp_tf_org_run_task](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/organization_run_task) | resource |
| [tfe_workspace.run_task_workspace](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/workspace) | resource |
| [tfe_workspace_run_task.pre_radar_runtask](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/workspace_run_task) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_hcp_client_id"></a> [hcp\_client\_id](#input\_hcp\_client\_id) | The client ID of HCP project for Vault Radar to use | `string` | n/a | yes |
| <a name="input_hcp_client_secret"></a> [hcp\_client\_secret](#input\_hcp\_client\_secret) | The client secret of HCP project for Vault Radar to use | `string` | n/a | yes |
| <a name="input_hcp_project_id"></a> [hcp\_project\_id](#input\_hcp\_project\_id) | The ID of HCP project for Vault Radar to use | `string` | n/a | yes |
| <a name="input_hcp_tf_org_name"></a> [hcp\_tf\_org\_name](#input\_hcp\_tf\_org\_name) | The name of the HCP Terraform organization to create the run task | `string` | n/a | yes |
| <a name="input_hcp_tf_workspace_name"></a> [hcp\_tf\_workspace\_name](#input\_hcp\_tf\_workspace\_name) | The name of the HCP Terraform workspace to attach the run task | `string` | `"terraform-shell-radar-runtask"` | no |
| <a name="input_hmac_key"></a> [hmac\_key](#input\_hmac\_key) | The HMAC key for the run task | `string` | `"abc123"` | no |
| <a name="input_name"></a> [name](#input\_name) | A name to apply to resources. The name must be unique within an AWS account | `string` | `"hcp-radar"` | no |
| <a name="input_randomize_name"></a> [randomize\_name](#input\_randomize\_name) | Whether to randomize the name of the resources | `bool` | `true` | no |
| <a name="input_run_task_enforcement_level"></a> [run\_task\_enforcement\_level](#input\_run\_task\_enforcement\_level) | The enforcement level for the run task | `string` | `"advisory"` | no |
| <a name="input_run_task_name"></a> [run\_task\_name](#input\_run\_task\_name) | The name of the run task | `string` | `"hcp-radar-runtask"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->