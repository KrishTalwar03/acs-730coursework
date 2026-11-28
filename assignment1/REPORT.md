# Assignment 1: Multi-environment AWS deployment

## Introduction

This assignment extends the ACS730 Terraform work into dev, staging, and production environments using one reusable web-stack module. It keeps each environment's remote state separate, deploys through GitHub Actions, stores an application value in Systems Manager Parameter Store, and monitors EC2 CPU utilization with CloudWatch. AWS Academy credentials remain temporary, session-scoped credentials; the OIDC policy below is a recommendation for a real AWS account because the Academy role cannot create the required identity provider and IAM role.

## Reusable infrastructure and environments

The module in `terraform/modules/web_stack/` creates a VPC, public subnet, internet routing, an EC2 nginx server, a security group, and a CloudWatch alarm. Its typed inputs cover the environment name, owner, address ranges, instance size, and SSM parameter name. Outputs expose resource IDs, the web URL, the alarm name, and the SSM parameter ARN. The security group allows HTTP on port 80 only from the administrator laptop CIDR, avoiding a world-open web rule. The provided laptop CIDR is `142.189.207.231/32`, taken from the supplied EC2 screenshot; it must be updated if the laptop's public IP changes.

The `dev/`, `staging/`, and `prod/` roots call the same module with non-overlapping VPC ranges. They use the course's existing encrypted S3 state bucket and separate keys: `assignment1/dev/terraform.tfstate`, `assignment1/staging/terraform.tfstate`, and `assignment1/prod/terraform.tfstate`. The GitHub workflow validates all three roots on pull requests. After a merge to `main`, it applies staging and then starts the protected prod job. The prod environment must have a required reviewer configured in repository settings; the workflow alone cannot enforce approval without that setting.

## Credentials and production OIDC trust policy

For the AWS Academy lab, the pipeline uses the three temporary credential secrets scoped to staging and prod. The helper refreshes them from the active Vocareum session. The GitHub setup script creates the environments, restricts prod deployments to `main`, and deletes repository-level credential copies only after it confirms all three environment secrets exist in both environments.

For a real AWS account, after registering GitHub's OIDC provider, the prod role trust policy should be scoped to this repository's `prod` environment and `main` branch:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GitHubActionsProdOnly",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:KrishTalwar03/acs-730coursework:environment:prod",
          "token.actions.githubusercontent.com:ref": "refs/heads/main"
        }
      }
    }
  ]
}
```

Replace `<AWS_ACCOUNT_ID>` with the account that owns the OIDC provider and role. The `aud` condition rejects tokens intended for another audience. The exact `sub` allows only this repository's prod environment and blocks other repositories, branches, and environments from assuming the role. The `ref` condition further requires the workflow run to come from `main`, even if a workflow references the prod environment from another branch. The GitHub environment's branch policy provides a second main-only deployment gate. AWS's [Terraform security guidance](https://docs.aws.amazon.com/prescriptive-guidance/latest/terraform-aws-provider-best-practices/security.html) also recommends restricting the GitHub OIDC subject rather than trusting a broad wildcard.

## Application secret and observability

Before deployment, `scripts/bootstrap-assignment1-secret.sh` stores a hidden, placeholder application value as the SSM SecureString `/acs730/assignment1/application-secret`. Terraform reads it with `data.aws_ssm_parameter` and requires a non-empty value before creating the instance. The secret is not emitted as an output or placed in the web server's user data. Terraform state can still contain values read by data sources, so the encrypted remote state bucket must be access-controlled and state access treated as sensitive. The CloudWatch alarm monitors the instance's real `AWS/EC2` `CPUUtilization` metric and enters alarm state after two consecutive five-minute periods above 80%; no notification action is configured.

## Recommendation: use an AWS-native pipeline for an AWS-only team

For a team committed to AWS with no multi-cloud plans, I recommend AWS CodePipeline with CodeBuild for Terraform validation and deployment. First, it can use AWS service roles for the pipeline and build jobs, so access can be granted and audited through IAM rather than maintaining a separate GitHub-to-AWS credential bridge. That aligns with an AWS-only operating model and avoids session-scoped access keys in repository secrets. Second, the pipeline integrates with AWS deployment stages and can pause at a manual approval action before production; approvers need explicit IAM permission, which gives the organization one place to manage who can release. Third, build and deployment activity fits directly into the AWS account's IAM and CloudTrail audit model, while the Terraform provider and state already live in AWS. These are concrete operational benefits when the team has no need to deploy to other clouds.

There are tradeoffs. GitHub Actions already sits beside the source code, has a familiar pull-request workflow, and provides environment-scoped secrets, branch controls, deployment history, and required reviewers. AWS CodePipeline requires pipeline configuration, service roles, and a source connection, and its approval stage needs separate IAM permissions (and optional SNS notifications). If the team is already standardized on GitHub Actions or values one workflow for mixed platforms, keeping Actions can be simpler. For this assignment, Actions is also the required pipeline, and AWS Academy restricts IAM setup, so its temporary session-credential workaround is a course constraint rather than a production design. GitHub's [environment documentation](https://docs.github.com/en/actions/concepts/workflows-and-actions/deployment-environments) and AWS's [CodePipeline approval guide](https://docs.aws.amazon.com/codepipeline/latest/userguide/approvals.html) describe the corresponding approval controls.

## Deployment and cleanup record

The repository workflow and Terraform configuration are prepared, but the real AWS and GitHub steps have not yet been recorded as completed. No deployment evidence is claimed here. After the files are pushed to `main`, record the Actions run and commit, confirm staging applies, approve and confirm prod, then capture the AWS resources and alarm. Finally, run the workflow's destroy action once for staging and once for prod, confirm both destroy jobs succeed, and update this section with the observed run links and cleanup result. Store genuine screenshots in `evidence/` with secret values hidden.

## Conclusion

The configuration now defines reusable infrastructure, three isolated Terraform environments, an approval-gated deployment path, a secure parameter lookup, and a CloudWatch metric alarm. Completion of the real-deployment portion depends on refreshing live Academy credentials, setting the prod reviewer, running the GitHub deployment, and destroying both deployed environments; the report must be updated with that observed evidence before submission.
