module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.app_name}-vpc"
  cidr = var.vpc_cidr

  azs             = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  private_subnets = var.private_subnets
  intra_subnets   = var.intra_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  enable_vpn_gateway = false
  single_nat_gateway = true
  one_nat_gateway_per_az = false
  enable_dns_hostnames = true

  tags = {
  Application_Name = local.app_name
  Application_ID   = local.app_id
  Environment      = local.env
  }
}

resource "aws_flow_log" "vpc_flow_log" {
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = module.vpc.vpc_id
  iam_role_arn         = aws_iam_role.flow_logs_role.arn
}
