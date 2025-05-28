terraform {
  required_version = ">= 1.6.0"
  backend "s3" {
    bucket  = "tech-challenge-terraf-state" #CHANGE IT
    key     = "techchallenge.tfstate"
    region  = "eu-central-1"
    profile = "techchallenge" #CHANGE IT
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Application_Name = local.app_name
      Application_ID   = local.app_id
      Environment      = local.env
    }
  }
}

locals {
  env = "prod"
  app_id = "tch"
  app_name = "tech-challenge"
}

data "aws_secretsmanager_secret" "github_token" {
  name = "github-token"
}

data "aws_secretsmanager_secret_version" "github_token" {
  secret_id = data.aws_secretsmanager_secret.github_token.id
}
