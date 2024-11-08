terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.74.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_role" {
  name = "lambda_ssm_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Policy for Lambda to Access SSM and CloudWatch Logs
resource "aws_iam_role_policy" "lambda_ssm_policy" {
  name = "lambda_ssm_policy"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda Function Resource
resource "aws_lambda_function" "ssm_lambda" {
  function_name = "SSMQueryLambda"
  runtime       = "python3.8"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  filename      = "lambda_function.zip" # Ensure this ZIP is available in your build directory

  environment {
    variables = {
      PARAMETER_NAME = "/example/parameter" # Update as needed
    }
  }
}

# S3 Bucket for CodePipeline Artifacts
resource "aws_s3_bucket" "artifacts_bucket" {
  bucket = "lambda-pipeline-artifacts-bucket"
}

# S3 Bucket ACL (Separate Resource to Avoid Deprecation Warning)
resource "aws_s3_bucket_acl" "artifacts_bucket_acl" {
  bucket = aws_s3_bucket.artifacts_bucket.id
  acl    = "private"
}

# IAM Role for CodePipeline
resource "aws_iam_role" "pipeline_role" {
  name = "pipeline_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# CodePipeline Definition
resource "aws_codepipeline" "lambda_pipeline" {
  name     = "LambdaSSMCodePipeline"
  role_arn = aws_iam_role.pipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifacts_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1" # Required version for CodePipeline actions
      output_artifacts = ["source_output"]

      configuration = {
        S3Bucket    = aws_s3_bucket.artifacts_bucket.bucket
        S3ObjectKey = "source/lambda_function.zip"
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1" # Required version for CodePipeline actions
      input_artifacts = ["source_output"]

      configuration = {
        ProjectName = aws_codebuild_project.lambda_build_project.name
      }
    }
  }
}

# CodeBuild Project for Lambda Deployment
resource "aws_codebuild_project" "lambda_build_project" {
  name         = "LambdaBuildProject"
  service_role = aws_iam_role.pipeline_role.arn

  source {
    type      = "S3"
    location  = aws_s3_bucket.artifacts_bucket.bucket
    buildspec = file("buildspec.yml") # Referencing buildspec file
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/python:3.8"
    type         = "LINUX_CONTAINER"
  }

  artifacts {
    type = "NO_ARTIFACTS" # No output artifacts needed for CodeBuild
  }
}
