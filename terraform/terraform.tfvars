# AWS provider configuration
aws_profile = "techchallenge"
aws_region  = "eu-central-1"

# VPC configuration
vpc_cidr      = "10.0.0.0/16"
private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
intra_subnets   = ["10.0.51.0/24", "10.0.52.0/24", "10.0.53.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

# IAM and account configuration
account_id = ""