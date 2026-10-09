# Lab 3



## Credential model

On a real AWS account, GitHub Actions should use OIDC to exchange short-lived signed tokens for AWS credentials, avoiding stored access keys. AWS Academy blocks the IAM permissions required to configure OIDC, so this lab stores Vocareum session credentials as GitHub Actions secrets; they expire with the lab session, limiting how long leaked credentials can be used.

Terraform version used: 1.10.3.

## Troubleshooting

- `ExpiredToken`: The lab session ended. Start a new session, run `./scripts/refresh-gha-creds.sh KrishTalwar03/acs-730coursework`, and rerun the workflow; no repository files need to change.
- `Input required and not supplied: aws-region`: The `AWS_REGION` variable is missing, not an AWS credential issue. Run the refresh script or set it with `gh variable set AWS_REGION --body us-east-1`.

# Lab 3: Terraform and AWS

## Overview
This lab uses Terraform to store a greeting in AWS Systems Manager Parameter Store. Terraform state is stored in an S3 backend.

## Resources
- SSM parameter: `/acs730/lab3/greeting`
- S3 state bucket: `acs730-tfstate-<AWS_ACCOUNT_ID>`
- AWS region: `us-east-1`

## GitHub Actions
The workflow runs `terraform plan` for pull requests and `terraform apply` when changes are merged to `main`. AWS credentials are stored as GitHub secrets; never commit credentials to the repository.

## Verify
From the repository root, run the course self-check:

    ./scripts/check-lab.sh lab3

To read the greeting from AWS:

    aws ssm get-parameter --name /acs730/lab3/greeting \
      --query 'Parameter.Value' --output text
## Experiments

### 1. Refreshing temporary AWS credentials

**Prediction:** If the GitHub Actions credentials cannot access the S3 state bucket, Terraform will fail to initialize. Refreshing the credentials from an active Vocareum session should restore access.

**Observed:** My first attempt failed with an S3 `403 Forbidden` error. After I ran the credential refresh script, I reran the workflow and it succeeded.

**Explanation:** Terraform needs AWS credentials to read the remote state in S3. Refreshing updated the GitHub repository credentials; the `403` message did not identify the exact cause of the access failure.

### 2. Migrating the Terraform state backend

**Prediction:** Removing the S3 backend configuration and running `terraform init -migrate-state` should copy the existing state to a local file without changing the AWS resource.

**Observed:** Terraform prompted me to copy the state from S3 to the local backend, and `terraform state list` showed `aws_ssm_parameter.lab3`. I restored the S3 backend configuration, reinitialized Terraform, confirmed the resource was still listed, and removed the local state files.

**Explanation:** The backend determines where Terraform stores state. This experiment moved the state between storage locations; I did not run `plan` or `apply`, so it made no infrastructure changes.
