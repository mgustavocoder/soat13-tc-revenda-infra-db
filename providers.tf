terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "terraform_remote_state" "k8s" {
  backend = "s3"

  config = {
    bucket = var.tf_state_bucket
    key    = "infra-k8s/terraform.tfstate"
    region = var.region
  }
}
