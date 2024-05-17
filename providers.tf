terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.47.0"
    }

    awscc = {
      source  = "hashicorp/awscc"
      version = ">= 0.24.0"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.0"
    }
  }
}
