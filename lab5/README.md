# Lab 5 - Terraform network and LocalStack CI

## What I built

One Terraform configuration selects real AWS or LocalStack with `use_localstack`.
It creates a VPC, two public subnets using `for_each`, an internet gateway,
a public route table and one association per subnet, a dynamic HTTP security
group, an EC2 instance with nginx user data, and an optional S3 bucket using
`count`. References wire the resources together. Region, availability zones,
and the real AWS Amazon Linux 2023 AMI are read from data sources rather than
hardcoded. LocalStack uses a placeholder AMI and does not boot a real server.

All inputs have types and descriptions. Project, VPC CIDR and instance type
have validation. The required owner input has no default; `localstack.tfvars`
sets it to `ktalwar3`. The provider adds course, lab and owner tags.

## Why for_each here and count there

Subnets have identities, so `for_each` keeps stable addresses such as
`aws_subnet.public["a"]` and `["b"]`. Adding key `c` adds one subnet; removing
`b` removes that subnet and its association without shifting the other keys.
The web instance uses the first sorted key, so removing that selected subnet
can also replace the instance. With count over a list, removing a middle
entry shifts later indices and can cause replacements of otherwise unchanged
subnets. The bucket is a single yes/no choice, so `count` is appropriate:
false gives zero instances, true gives one. `one(resource[*].bucket)` returns
null for zero instances instead of raising an invalid-index error.

## Why not plan and apply against real AWS on every pull request

The Academy budget is $50 for the term. Repeated real deployments by a class
of 27 students consume that shared learning budget, and failed cleanup can
leave billable resources. LocalStack runs without creating real AWS resources.

CI should not need a long-lived AWS access key. Academy IAM restrictions make
least-privilege setup difficult, while session credentials expire after hours
and can make an unchanged pull request fail when the lab session ends. Real
AWS provisioning also introduces API delays, rate limits, eventual consistency
and collisions between concurrent pull requests sharing an account and state.

The first CI job checks formatting and validation without AWS credentials.
Only after it succeeds does a second job start the Terraform plan/apply steps
against a LocalStack service. The workflow contains no AWS secrets or AWS
credential setup action; the provider's literal `test` values are emulator
placeholders. An always-run destroy step cleans up the emulator state.

A passing LocalStack run proves that the configuration and dependency graph
work with the emulator. It does not prove real AWS IAM permissions, boot-time
package installation, or HTTP reachability. An approved real AWS integration
check belongs after merge or on a schedule, rather than on every pull request.

## Experiments

### 1. Turn the bucket off

Prediction: overriding `create_artifact_bucket=false` will destroy only the
bucket and make its output null; the web and network resources will remain.
The plan, apply and output evidence are saved under `evidence/experiment-bucket-*`.
The console expression `one(aws_s3_bucket.artifacts[*].bucket)` checks the null
value directly, because Terraform omits null outputs from its saved outputs.
The input is restored to true afterward. Using `[0]` instead of `one(...)`
would cause an invalid-index error when the list is empty.

### 2. Remove depends_on temporarily

Prediction: removing the explicit route-association dependency after apply
will produce no resource changes, because it changes creation order rather
than a resource attribute. The actual plan is saved in
`evidence/experiment-without-depends-on-plan.txt`; the dependency is restored.
Subnet and security-group references do not imply that route associations
must exist before the instance starts. Without the explicit edge, first-boot
package installation can run before internet routing exists. LocalStack cannot
expose that boot failure because it does not execute the instance's user data.

## Reproduce the local run

Run from `lab5/` on the EC2 workstation:

```bash
docker run -d --name localstack -p 4566:4566 \
  -e SERVICES=ec2,s3,sts,iam localstack/localstack:3.8
curl -sf http://localhost:4566/_localstack/health
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -var-file=localstack.tfvars -out=tfplan
terraform apply -auto-approve tfplan
terraform output
terraform destroy -auto-approve -var-file=localstack.tfvars
AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 \
  aws --endpoint-url=http://localhost:4566 ec2 describe-vpcs --output json
docker stop localstack
```

Wait for the health endpoint to respond before planning. If a container named
`localstack` already exists, use `docker start localstack` instead of creating
another. `provider_target` must say `localstack (http://localhost:4566)`.
LocalStack's default VPC can remain after destroy; the lab's `10.42.0.0/16`
must be absent. Never commit `.terraform/`, state, saved plans or private keys.
Commit `.terraform.lock.hcl`.

## One screenshot and supporting evidence

Use exactly one screenshot: the deliberate-failure pull request showing a
failed `fmt and validate` check, skipped LocalStack job, and disabled merge
button due to required checks. Save it as `evidence/required-check-blocked.png`.
The text/JSON evidence records the successful run, deliberate failure,
post-fix checks, two experiments and VPC teardown without extra screenshots.
