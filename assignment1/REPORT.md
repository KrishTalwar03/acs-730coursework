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

Replace `<AWS_ACCOUNT_ID>` with the account that owns the OIDC provider and role. The `aud` condition rejects tokens intended for an audience other than AWS STS. The exact `sub` pins the token to this repository's `prod` environment; unlike a repository-wide wildcard, it prevents another repository or environment from using the role. Because an environment-form `sub` does not itself distinguish branches, the `ref` condition separately requires `refs/heads/main`. Without these restrictions, someone able to push a workflow change to another branch could make that workflow request AWS credentials and deploy unreviewed code. The GitHub environment's branch policy adds another main-only gate. This policy was not deployed: AWS Academy denies the IAM permissions needed to register GitHub's OIDC provider and create the federated role. AWS's [Terraform security guidance](https://docs.aws.amazon.com/prescriptive-guidance/latest/terraform-aws-provider-best-practices/security.html) also recommends restricting the GitHub OIDC subject rather than trusting a broad wildcard.

## Application secret and observability

The one-time workstation pre-step creates `/acs730/assignment1/application-secret` as a SecureString before the first Terraform plan. For the lab, use a harmless placeholder in place of `<PLACEHOLDER_VALUE>`; do not commit the real value.

```bash
aws ssm put-parameter \
  --name /acs730/assignment1/application-secret \
  --type SecureString \
  --value "<PLACEHOLDER_VALUE>" \
  --overwrite \
  --region us-east-1
```

The helper `scripts/bootstrap-assignment1-secret.sh` prompts for the value without echoing it and runs this pre-step. Terraform only reads the parameter through `data.aws_ssm_parameter`; there is no Terraform resource creating it. The data source requires a non-empty value before creating the instance, but the secret is not emitted as an output or placed in web-server user data. Terraform state can still contain values read by data sources, so the encrypted remote state bucket must be access-controlled and state access treated as sensitive. The CloudWatch alarm monitors the real `AWS/EC2` `CPUUtilization` metric and enters alarm state after two consecutive five-minute periods above 80%; no notification action is configured.

## Recommendation: use an AWS-native pipeline for an AWS-only team

For a team committed to AWS with no multi-cloud plans, I recommend AWS CodePipeline with CodeBuild. First, pipeline and build identities can be AWS IAM service roles, so permissions and audit records stay with the AWS account instead of bridging GitHub to AWS with stored keys. Second, CodeBuild can run in the team's VPC and reach private databases or internal services; a GitHub-hosted runner cannot reach those private addresses without extra network infrastructure. Third, AWS manages the CodeBuild environment image and its patching, while the team pays for configured build capacity and can keep build usage on the same AWS bill as its deployments. This reduces runner administration and makes VPC access straightforward. Fourth, CodePipeline can pause before production, and IAM permissions determine who may approve; this fits an AWS team's existing identity and change-control model. AWS documents [CodeBuild VPC access](https://docs.aws.amazon.com/codebuild/latest/userguide/vpc-support.html) and [manual approval actions](https://docs.aws.amazon.com/codepipeline/latest/userguide/approvals.html).

The practical case for GitHub Actions is strong too: this repository already uses it, developers understand pull requests, and GitHub provides environment-scoped secrets, branch controls, and approval gates. Since the repository is public, standard GitHub-hosted runner usage is free; that can be cheaper and simpler for a small course project. GitHub documents its [Actions billing rules](https://docs.github.com/en/actions/concepts/billing-and-usage) and [deployment environments](https://docs.github.com/en/actions/concepts/workflows-and-actions/deployment-environments). However, the team has no multi-cloud requirement, and AWS-native runner identity and private-network access outweigh keeping one familiar tool. Therefore I recommend CodePipeline and CodeBuild for this AWS-only team.

## Deployment and cleanup record

The Assignment 1 workflow's dev, staging, and prod format/validation checks have passed on pull request #19. The real AWS and GitHub environment steps have not yet been recorded as completed, so no deployment or cleanup evidence is claimed here. Before merging, set up environment-scoped credentials and create the SSM parameter. After merging, save staging's apply log, capture the pending prod approval screenshot before clicking, approve prod, save its apply log, and capture the SSM and alarm evidence. Then destroy dev, staging, and prod, save the combined output as `evidence/destroy-complete.txt`, and confirm the course cleanup check reports nothing running. Add the required evidence files from `evidence/README.md` and replace this paragraph with the observed run and cleanup record.

## Conclusion

This design uses reusable infrastructure and a gated path to apply the same stack in three environments, while the real account proves whether its temporary credentials and Academy permissions support the plan. The next decision is operational: refresh the session, capture the approval gate and alarm after they have real evidence, then destroy all three environments before the Academy budget is consumed. The recommendation for an AWS-only team remains CodePipeline with CodeBuild; the assignment uses GitHub Actions because that is the required course pipeline.
