# Lab 3

Instructions for this section will be provided in class and on Blackboard when we reach it.

Put your work for Lab 3 in this folder.

## Credential model

On a real AWS account, GitHub Actions should use OIDC to exchange short-lived signed tokens for AWS credentials, avoiding stored access keys. AWS Academy blocks the IAM permissions required to configure OIDC, so this lab stores Vocareum session credentials as GitHub Actions secrets; they expire with the lab session, limiting how long leaked credentials can be used.

Terraform version used: 1.10.3.

## Troubleshooting

- `ExpiredToken`: The lab session ended. Start a new session, run `./scripts/refresh-gha-creds.sh KrishTalwar03/acs-730coursework`, and rerun the workflow; no repository files need to change.
- `Input required and not supplied: aws-region`: The `AWS_REGION` variable is missing, not an AWS credential issue. Run the refresh script or set it with `gh variable set AWS_REGION --body us-east-1`.
