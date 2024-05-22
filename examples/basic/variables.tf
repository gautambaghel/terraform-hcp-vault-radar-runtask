variable "hcp_project_id" {
  type        = string
  description = "The ID of HCP project for Vault Radar to use"
}

variable "hcp_client_id" {
  type        = string
  description = "The client ID of HCP project for Vault Radar to use"
}

variable "hcp_client_secret" {
  type        = string
  description = "The client secret of HCP project for Vault Radar to use"
}

variable "hcp_tf_org_name" {
  type        = string
  description = "The name of the HCP Terraform organization to create the run task"
}

variable "randomize_name" {
  type        = bool
  description = "Whether to randomize the name of the resources"
  default     = true
}

variable "name" {
  type        = string
  description = "A name to apply to resources. The name must be unique within an AWS account"
  default     = "hcp-radar"
}

variable "hcp_tf_workspace_name" {
  type        = string
  description = "The name of the HCP Terraform workspace to attach the run task"
  default     = "terraform-shell-radar-runtask"
}

variable "run_task_name" {
  type        = string
  description = "The name of the run task"
  default     = "hcp-radar-runtask"
}

variable "hmac_key" {
  type        = string
  description = "The HMAC key for the run task"
  default     = "abc123"
}

variable "run_task_enforcement_level" {
  type        = string
  description = "The enforcement level for the run task"
  default     = "advisory"
}
