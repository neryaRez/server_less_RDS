variable "circleci_org_id" {
  type = string
}

variable "circleci_project_id" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "tls_certificate" "circleci" {
  url = "https://oidc.circleci.com/org/${var.circleci_org_id}"
}

resource "aws_iam_openid_connect_provider" "circleci" {
  url = "https://oidc.circleci.com/org/${var.circleci_org_id}"

  client_id_list = [
    var.circleci_org_id
  ]

  thumbprint_list = [
    data.tls_certificate.circleci.certificates[0].sha1_fingerprint
  ]
}

resource "aws_iam_role" "circleci_deploy_role" {
  name = "circleci-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.circleci.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "oidc.circleci.com/org/${var.circleci_org_id}:aud"                          = var.circleci_org_id
            "oidc.circleci.com/org/${var.circleci_org_id}:oidc.circleci.com/project-id" = var.circleci_project_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "circleci_deploy_policy" {
  name = "circleci-deploy-policy"
  role = aws_iam_role.circleci_deploy_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudformation:*",
          "lambda:*",
          "apigateway:*",
          "iam:PassRole",
          "iam:GetRole",
          "iam:CreateRole",
          "iam:AttachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:DetachRolePolicy",
          "iam:DeleteRole",
          "logs:*",
          "sqs:*",
          "sns:*",
          "ssm:*",
          "xray:*",
          "s3:*",
          "ec2:*",
          "rds:*"
        ]
        Resource = "*"
      }
    ]
  })
}

output "circleci_role_arn" {
  value = aws_iam_role.circleci_deploy_role.arn
}