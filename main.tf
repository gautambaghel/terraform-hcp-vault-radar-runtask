data "aws_region" "current" {}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

locals {
  name = var.randomize_name ? "${var.name}-${random_string.suffix.result}" : var.name
}

resource "aws_ssm_parameter" "hcp_project_id" {
  name        = "/hcp-vault-radar/hcp-project-id/${local.name}"
  description = "HCP Project Id"
  type        = "SecureString"
  value       = var.hcp_project_id
}

resource "aws_ssm_parameter" "hcp_client_id" {
  name        = "/hcp-vault-radar/hcp-client-id/${local.name}"
  description = "HCP Client Id"
  type        = "SecureString"
  value       = var.hcp_client_id
}

resource "aws_ssm_parameter" "hcp_client_secret" {
  name        = "/hcp-vault-radar/hcp-client-secret/${local.name}"
  description = "HCP Client Secret"
  type        = "SecureString"
  value       = var.hcp_client_secret
}

resource "aws_ecs_task_definition" "hcp_vault_radar" {
  family                   = local.name
  cpu                      = var.ecs_cpu
  memory                   = var.ecs_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  runtime_platform {
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode(
    [
      {
        name : "hcp-vault-radar"
        image : var.radar_runtask_image
        essential : true
        cpu : 0
        memory : 256
        logConfiguration : {
          logDriver : "awslogs",
          options : {
            awslogs-create-group : "true",
            awslogs-group : var.cloudwatch_log_group_name
            awslogs-region : data.aws_region.current.name
            awslogs-stream-prefix : "${local.name}"
          }
        }
        portMappings : [
          {
            containerPort : 80
            hostPort : 80
            protocol : "tcp"
          }
        ]
        environment = concat([{
          name  = "PORT",
          value = "80"
          }
        ], var.extra_env_vars),
        secrets = [
          {
            name      = "HCP_CLIENT_ID",
            valueFrom = aws_ssm_parameter.hcp_client_id.arn
          },
          {
            name      = "HCP_CLIENT_SECRET",
            valueFrom = aws_ssm_parameter.hcp_client_secret.arn
          },
          {
            name      = "HCP_PROJECT_ID",
            valueFrom = aws_ssm_parameter.hcp_project_id.arn
          }
        ]
      }
    ]
  )
}

resource "aws_ecs_service" "hcp_vault_radar" {
  name            = local.name
  cluster         = var.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.hcp_vault_radar.arn
  desired_count   = var.ecs_desired_count
  propagate_tags  = "SERVICE"

  deployment_maximum_percent         = "200"
  deployment_minimum_healthy_percent = "33"
  enable_ecs_managed_tags            = "true"


  capacity_provider_strategy {
    capacity_provider = var.use_spot_instances ? "FARGATE_SPOT" : "FARGATE"
    weight            = "1"
  }

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.hcp_vault_radar.id]
    subnets          = var.subnet_ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.hcp_vault_radar.arn
    container_name   = "hcp-vault-radar"
    container_port   = 80
  }

  lifecycle {
    postcondition {
      condition     = self.desired_count == var.ecs_desired_count
      error_message = "The ECS service desired count is not equal to the number of instances specified in the configuration."
    }
  }

  tags = {
    Name = "${local.name}"
  }
}

resource "aws_lb_target_group" "hcp_vault_radar" {
  name        = local.name
  vpc_id      = var.vpc_id
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "hcp_vault_radar" {
  load_balancer_arn = aws_lb.hcp_vault_radar.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hcp_vault_radar.arn
  }
}

resource "aws_lb" "hcp_vault_radar" {
  name               = local.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.hcp_vault_radar.id]
  subnets            = var.subnet_ids
  tags = {
    Name = "${local.name}"
  }
}

moved {
  from = aws_ecs_service.hcp-vault-radar
  to   = aws_ecs_service.hcp_vault_radar
}

resource "aws_security_group" "hcp_vault_radar" {
  name_prefix = "${local.name}-sg"
  description = "Security group for HCP Vault Radar: ${local.name}"
  vpc_id      = var.vpc_id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_ingress" {
  protocol          = "tcp"
  type              = "ingress"
  for_each          = var.radar_ingress_ports
  from_port         = each.value
  to_port           = each.value
  cidr_blocks       = var.radar_cidr_blocks
  security_group_id = aws_security_group.hcp_vault_radar.id
}

resource "aws_security_group_rule" "allow_egress" {
  cidr_blocks       = var.radar_cidr_blocks
  security_group_id = aws_security_group.hcp_vault_radar.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
}

#####################################################################################
# IAM
# Two roles are defined: the task execution role used during initialization,
# and the task role which is assumed by the container(s).
#####################################################################################

data "aws_iam_policy_document" "radar_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${local.name}-ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.radar_assume_role_policy.json
  tags = {
    Name = "${local.name}-ecsTaskExecutionRole"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "radar_init_policy" {
  statement {
    effect  = "Allow"
    actions = ["ssm:GetParameters"]
    resources = [
      aws_ssm_parameter.hcp_client_id.arn,
      aws_ssm_parameter.hcp_client_secret.arn,
      aws_ssm_parameter.hcp_project_id.arn
    ]
  }
}

resource "aws_iam_role_policy" "radar_init_policy" {
  role   = aws_iam_role.ecs_task_execution_role.name
  name   = "AccessSSMforRadarToken"
  policy = data.aws_iam_policy_document.radar_init_policy.json
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${local.name}-ecsTaskRole"
  assume_role_policy = data.aws_iam_policy_document.radar_assume_role_policy.json
  tags = {
    Name = "${local.name}-ecsTaskRole"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy_attachment" {
  for_each = toset(var.task_policy_arns)

  role       = aws_iam_role.ecs_task_role.name
  policy_arn = each.key
}


#####################################################################################
# API Gateway
# Refer: https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-private-integration.html
#####################################################################################

# resource "aws_apigatewayv2_vpc_link" "private_integration_vpc_link" {
#   name               = local.name
#   security_group_ids = [aws_security_group.hcp_vault_radar.id]
#   subnet_ids         = var.subnet_ids

#   tags = {
#     Usage = "HCPVaultRadarVPCLink"
#   }
# }

# resource "aws_apigatewayv2_api" "http_api" {
#   name          = local.name
#   protocol_type = "HTTP"
#   description   = "HTTP API for HCP Vault Radar run task"

#   cors_configuration {
#     allow_methods = ["POST", "GET"]
#     allow_origins = ["*"] # Change to app.terraform.io
#   }
# }

# resource "aws_apigatewayv2_stage" "stage" {
#   api_id      = aws_apigatewayv2_api.http_api.id
#   name        = "$default"
#   auto_deploy = true

#   access_log_settings {
#     destination_arn = var.cloudwatch_log_group_arn
#     format          = "$context.requestId"
#   }
# }

# resource "aws_apigatewayv2_route" "route" {
#   api_id    = aws_apigatewayv2_api.http_api.id
#   route_key = "ANY /{proxy+}"

#   target = "integrations/${aws_apigatewayv2_integration.private_integration.id}"
# }

# resource "aws_apigatewayv2_integration" "private_integration" {
#   api_id           = aws_apigatewayv2_api.http_api.id
#   description      = "HCP Vault Radar run task with a load balancer"
#   integration_type = "HTTP_PROXY"
#   integration_uri  = aws_lb_listener.hcp_vault_radar.arn

#   connection_type = "VPC_LINK"
#   connection_id   = aws_apigatewayv2_vpc_link.private_integration_vpc_link.id

#   integration_method   = "POST"
#   timeout_milliseconds = 3000

#   # tls_config {
#   #   server_name_to_verify = "app.terraform.io"  # change for Terraform Enterprise
#   # }
# }
