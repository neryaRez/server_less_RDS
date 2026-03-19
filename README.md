# Aurora Serverless Provisioning Automation

A cloud automation project for provisioning Aurora environments in AWS through an API-driven workflow.

Instead of manually editing infrastructure files for every new database request, this project accepts a request through an API, generates the matching Terraform input automatically, opens a Pull Request in GitHub, and lets CircleCI complete the provisioning flow.

I built this project to demonstrate practical work across serverless architecture, Terraform, CI/CD, and secure AWS automation.

---

## Overview

The system receives a request containing:

- `database_name`
- `database_engine`
- `environment`

From there, the flow is:

1. API Gateway receives the request
2. SNS forwards it to SQS
3. Lambda validates the payload
4. Lambda creates a matching `.tfvars` request file
5. Lambda opens a Pull Request in GitHub
6. CircleCI runs the pipeline
7. Terraform provisions the Aurora environment in AWS

In other words, this project turns a simple API request into a controlled infrastructure provisioning workflow.

---

## Technologies Used

- AWS SAM
- API Gateway
- SNS
- SQS
- AWS Lambda
- Terraform
- Aurora Serverless v2
- CircleCI
- OIDC
- AWS Systems Manager Parameter Store
- KMS
- S3 + DynamoDB for remote Terraform state

---

## Repository Structure

```text
.
├── config/
├── server_less/
├── .circleci/
└── IaC_Code/
    ├── backend/
    ├── oidc_circleCI/
    ├── root/
    └── modules/rds-cluster/
```

---

## Running the Project

Before you start, make sure you have:

- AWS CLI installed and configured
- AWS SAM CLI installed
- Terraform installed
- A **CircleCI project** connected to your GitHub repository
- A **GitHub Personal Access Token** with permissions to create branches, commits, and pull requests


### 1. Deploy the serverless stack

```bash
cd server_less
sam build
sam deploy
```

This creates the API Gateway, SNS, SQS, DLQ, Lambda, and the required IAM resources.

### 2. Store the GitHub token in SSM

```bash
aws ssm put-parameter \
  --name "/aurora-serverless/github/token" \
  --type "SecureString" \
  --value "<your-github-token>"
```

### 3. Deploy the Terraform backend

```bash
cd IaC_Code/backend
terraform init
terraform apply
```

### 4. Deploy the CircleCI OIDC infrastructure

```bash
cd IaC_Code/oidc_circleCI
./init.sh
terraform apply
```

### 5. Configure CircleCI

Create a CircleCI project connected to the repository and define the required environment variables there,  in the config/.env.example file including:

- `AWS_ROLE_ARN`
- `AWS_REGION`
- `SAM_STACK_NAME`
- `PROJECT_NAME`
- `GITHUB_OWNER`
- `GITHUB_REPO`

### 6. Send a provisioning request

Use the API Gateway URL from the SAM stack outputs and send a POST request such as:

```json
{
  "database_name": "ordersdb",
  "database_engine": "postgresql",
  "environment": "prod"
}
```

---

## Example Request

```bash
curl -X POST "https://<api-id>.execute-api.<region>.amazonaws.com/api/requests" \
  -H "Content-Type: application/json" \
  -d '{
    "database_name": "ordersdb",
    "database_engine": "postgresql",
    "environment": "prod"
  }'
```

---

## What This Project Demonstrates

The project shows:

- practical use of AWS serverless services
- modular Infrastructure as Code with Terraform
- remote backend and state locking
- secure CI/CD access to AWS using OIDC
- automation of infrastructure requests through GitHub Pull Requests
- separation between development and production provisioning logic

More broadly, the project reflects the way I like to build systems: with automation, structure, and a flow that is closer to real platform engineering work than to a simple isolated demo.

---

## About Me

My name is **Nerya Reznikovich**, and I built this project as part of my learning journey in cloud, DevOps, and platform engineering.

I enjoy building hands-on systems that combine infrastructure, automation, and software development, especially projects that simulate real operational workflows and not only basic service deployment demos.