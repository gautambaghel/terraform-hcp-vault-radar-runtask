#####################################################################################
# Terraform module examples are meant to show an _example_ on how to use a module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own root module that invokes this module
#####################################################################################

data "aws_availability_zones" "available" {}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

locals {
  region         = "us-west-2"
  azs            = slice(data.aws_availability_zones.available.names, 0, 3)
  name           = var.randomize_name ? "${var.name}-${random_string.suffix.result}" : var.name
  workspace_name = var.randomize_name ? "${var.hcp_tf_workspace_name}-${random_string.suffix.result}" : var.hcp_tf_workspace_name
  run_task_name  = var.randomize_name ? "${var.run_task_name}-${random_string.suffix.result}" : var.run_task_name
  vpc_cidr       = "10.0.0.0/16"
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

#####################################################################################
# MODULE INVOCATION
#####################################################################################

module "radar_runtask" {
  source                    = "../../"
  name                      = local.name
  hcp_client_id             = var.hcp_client_id
  hcp_client_secret         = var.hcp_client_secret
  hcp_project_id            = var.hcp_project_id
  use_spot_instances        = true
  ecs_cpu                   = 512
  ecs_memory                = 1024
  ecs_cluster_arn           = module.ecs_cluster.cluster_arn
  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.public_subnets
  cloudwatch_log_group_name = aws_cloudwatch_log_group.cloudwatch.name
  cloudwatch_log_group_arn  = aws_cloudwatch_log_group.cloudwatch.arn
}

#####################################################################################
# HCP Terraform configuration
#####################################################################################

data "tfe_organization" "hcp_tf_org" {
  name = var.hcp_tf_org_name
}

resource "tfe_organization_run_task" "hcp_tf_org_run_task" {
  organization = data.tfe_organization.hcp_tf_org.name
  url          = module.radar_runtask.runtask_url
  name         = local.run_task_name
  hmac_key     = var.hmac_key
  enabled      = true
  description  = "HCP Radar run task to scan for secrets and keys in Terraform configurations"
}

resource "tfe_workspace" "run_task_workspace" {
  organization = data.tfe_organization.hcp_tf_org.name
  name         = local.workspace_name
  auto_apply   = true
}

resource "tfe_workspace_run_task" "pre_radar_runtask" {
  workspace_id      = tfe_workspace.run_task_workspace.id
  task_id           = tfe_organization_run_task.hcp_tf_org_run_task.id
  enforcement_level = var.run_task_enforcement_level
  stage             = "pre_plan"
}

#####################################################################################
# VPC
#####################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.tags
}

#####################################################################################
# ECS CLUSTER DEFINITION
#####################################################################################

resource "aws_cloudwatch_log_group" "cloudwatch" {
  name              = "/ecs/hcp-vault-radar/${local.name}"
  retention_in_days = 7
}

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.0"

  cluster_name = local.name

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 20
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  tags = local.tags
}

