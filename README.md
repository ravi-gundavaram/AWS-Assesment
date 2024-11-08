# AWS-Assesment
AWS-Assesment-incushell
# AWS Lambda Deployment with Terraform and CodePipeline

This repository contains an assessment solution that deploys an AWS Lambda function using Infrastructure as Code (IaC) with Terraform and AWS CodePipeline. The Lambda function queries AWS Systems Manager (SSM) Parameter Store to retrieve a parameter value.

## Prerequisites

1. **AWS Account** with permissions to create Lambda, SSM, IAM, S3, CodePipeline, and CodeBuild resources.
2. **AWS CLI** installed and configured with sufficient permissions.
3. **Terraform** installed (recommended version >= 0.12).
4. **Git** installed for source code version control.
5. **S3 Bucket** to store Lambda code for CodePipeline’s source stage (you can create this in the `main.tf` if you don't have one).

## Setup Instructions

### 1. Create and Package Lambda Function

1. Write the Lambda function in `lambda_function.py`.
2. Package the Lambda function as a ZIP file for deployment:

   zip lambda_function.zip lambda_function.py
