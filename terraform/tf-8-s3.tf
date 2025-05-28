resource "aws_s3_bucket" "pipeline_bucket" {
  bucket = "${local.app_name}-codepipeline-bucket"
}