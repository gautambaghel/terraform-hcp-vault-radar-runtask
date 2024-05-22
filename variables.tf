variable "name" {
  type        = string
  description = "A name to apply to resources. The name must be unique within an AWS account."
}

variable "randomize_name" {
  type        = bool
  description = "Whether to randomize the name of the resources."
  default     = true
}

variable "hcp_project_id" {
  type        = string
  description = "The ID of the HCP project to use."
}

variable "hcp_client_id" {
  type        = string
  description = "The client ID for the HCP project."
}

variable "hcp_client_secret" {
  type        = string
  description = "The client secret for the HCP project."
}

variable "cloudwatch_log_group_arn" {
  type        = string
  description = "The ARN of the CloudWatch log group where agent logs will be sent."
}

variable "cloudwatch_log_group_name" {
  type        = string
  description = "The name of the CloudWatch log group where agent logs will be sent."
}

variable "radar_runtask_image" {
  type        = string
  description = "The Docker image with Terraform runtask server & Radar installed."
  default     = "baghelg/hcp-radar-runtask:latest"
}

variable "radar_ingress_ports" {
  type        = set(string)
  description = "Ingress ports to allow the agent to communicate with the HCP Vault Radar."
  default     = ["80"]
}

variable "radar_egress_ports" {
  type        = set(string)
  description = "Egress ports to allow the agent to communicate with the HCP Vault Radar."
  default     = ["0"]
}

variable "radar_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks to allow the agent to communicate with the HCP Vault Radar."
  default     = ["0.0.0.0/0"]
}

variable "ecs_cpu" {
  type        = number
  description = "The CPU units allocated to the agent container(s). See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html#fargate-tasks-size"
  default     = 512
  validation {
    condition     = var.ecs_cpu >= 512
    error_message = "The CPU value must be at least 512."
  }
}

variable "ecs_memory" {
  type        = number
  description = "The amount of memory, in MB, allocated to the agent container(s)."
  default     = 1024
  validation {
    condition     = var.ecs_memory >= 1024
    error_message = "The memory value must be at least 1024."
  }
}

variable "ecs_desired_count" {
  type        = number
  description = "The number of agent containers to run."
  default     = 1
}

variable "ecs_cluster_arn" {
  type        = string
  description = "ARN of the ECS cluster where the agent will be deployed."
  validation {
    condition     = can(regex("^arn:aws[a-z-]*:ecs:", var.ecs_cluster_arn))
    error_message = "Must be a valid ECS cluster ARN."
  }
}

variable "use_spot_instances" {
  type        = bool
  description = "Whether to use Fargate Spot instances."
  default     = false
}

variable "extra_env_vars" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Extra environment variables to pass to the agent container."
  default     = []
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC where the cluster is running."
  validation {
    condition     = can(regex("^vpc-[a-zA-Z0-9]+$", var.vpc_id))
    error_message = "Must be a valid VPC ID."
  }
}

variable "subnet_ids" {
  type        = list(string)
  description = "IDs of the subnet(s) where agents can be deployed (public subnets required)"
  validation {
    condition = alltrue([
      for i in var.subnet_ids : can(regex("^subnet-[a-zA-Z0-9]+$", i))
    ])
    error_message = "Must be a list of valid subnet IDs."
  }
}

variable "task_policy_arns" {
  type        = list(string)
  description = "ARN(s) of IAM policies to attach to the agent task. Determines what actions the agent can take without requiring additional AWS credentials."
  default     = []
}
