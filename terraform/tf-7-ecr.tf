resource "aws_ecr_repository" "reverse_proxy" {
  name = "${local.app_name}-reverse-proxy"
}

resource "aws_ecr_repository" "rest_api" {
  name = "${local.app_name}-rest-api"
}
