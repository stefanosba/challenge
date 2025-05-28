# AWS provider configuration
variable "aws_profile" {
  description = "The AWS profile to use for the AWS provider."
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "eu-central-1"
}

# VPC configuration
variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "public_subnets" {
  description = "The CIDR blocks for public subnets."
  type        = list(string)
}

variable "private_subnets" {
  description = "The CIDR blocks for private subnets."
  type        = list(string)
}

variable "intra_subnets" {
  description = "The CIDR blocks for intra-subnets."
  type        = list(string)
}

# IAM and account configuration
variable "account_id" {
  description = "The AWS account ID."
  type        = string
}

variable "github_oauth_token" {
  description = "GitHub OAuth Token"
  type        = string
  sensitive   = true
}
