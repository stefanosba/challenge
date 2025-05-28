output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "reverse_proxy_repo_url" {
  value = aws_ecr_repository.reverse_proxy.repository_url
}

output "rest_api_repo_url" {
  value = aws_ecr_repository.rest_api.repository_url
}
