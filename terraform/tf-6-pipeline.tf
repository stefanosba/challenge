resource "aws_codebuild_project" "build" {
  name          = "${local.app_name}-build"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = var.account_id
    }
    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "CLUSTER_NAME"
      value = aws_ecs_cluster.ecs.name
    }
    environment_variable {
      name  = "SERVICE_NAME"
      value = aws_ecs_service.app.name
    }
    environment_variable {
      name  = "ECR_REPOSITORY_REVERSE_PROXY"
      value = aws_ecr_repository.reverse_proxy.name
    }
    environment_variable {
      name  = "ECR_REPOSITORY_API"
      value = aws_ecr_repository.rest_api.name
    }
  }

  source {
    type      = "GITHUB"
    location  = "https://github.com/stefanosba/challenge.git"
      buildspec = <<EOF
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
      - PROXY_REPO=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/${aws_ecr_repository.reverse_proxy.name}
      - API_REPO=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/${aws_ecr_repository.rest_api.name}

  build:
    commands:
      - echo Building reverse-proxy...
      - docker build -t $PROXY_REPO:latest reverse-proxy
      - echo Building rest-api...
      - docker build -t $API_REPO:latest rest-api

  post_build:
    commands:
      - echo Pushing images to ECR...
      - docker push $PROXY_REPO:latest
      - docker push $API_REPO:latest
      - aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force-new-deployment --region $AWS_REGION
EOF
  }
}

resource "aws_codepipeline" "pipeline" {
  name     = "${local.app_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = "stefanosba"
        Repo       = "challenge"
        Branch     = "main"
        OAuthToken = var.github_oauth_token
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }
}
