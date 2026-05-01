terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # S3 backend with built-in state locking (no DynamoDB required)
  # Terraform 1.5+ supports native S3 state locking without external DynamoDB
  backend "s3" {
    bucket         = "shopease-terraform-state"
    key            = "1-infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    skip_credentials_validation = false
    skip_metadata_api_check     = false
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Layer     = "1-infrastructure"
    }
  }
}
