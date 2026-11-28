# Assignment 1: Multi-environment Terraform delivery

This directory extends the course's Lab 5 AWS network and nginx instance into a reusable Terraform module and three independently stateful environments. The GitHub Actions workflow plans on pull requests, applies staging after a change reaches `main`, then pauses at the protected `prod` environment before applying production.

## Layout

- `terraform/modules/web_stack/` contains the shared VPC, public subnet, security group, EC2 web server, Parameter Store lookup, and CloudWatch alarm.
- `terraform/dev/`, `terraform/staging/`, and `terraform/prod/` each call that module and use their own S3 backend key.
- `evidence/README.md` lists the screenshots and run details to capture from the real GitHub and AWS Academy deployment.
- `.github/workflows/assignment1-deploy.yml` runs the staged deployment pipeline.

## Prerequisites

1. The course state bucket `acs730-tfstate-928670087602` must exist in `us-east-1`, and your AWS Academy session role must be allowed to use it and manage the assignment resources.
2. Create the SecureString `/acs730/assignment1/application-secret` in Systems Manager Parameter Store before the first workflow deployment. From an active Academy session, use `bash scripts/bootstrap-assignment1-secret.sh`; enter a placeholder value at the hidden prompt. Do not put the value in Git, a `.tfvars` file, a workflow, or a command-line argument. Terraform reads this parameter using a data source and never outputs its value.
3. Install and authenticate GitHub CLI (`gh auth login`). Run `bash scripts/configure-assignment1-github.sh KrishTalwar03/acs-730coursework KrishTalwar03` to create the environments, enforce the prod `main` branch policy, and configure your account as required reviewer. Self-review remains allowed so you can approve the job. For a stronger two-person gate, pass an instructor or teammate's username instead and enable Prevent self-review in the prod environment settings. If you omit the second argument, set a reviewer in GitHub Settings > Environments > prod.
4. At the start of each lab session, start Vocareum and run `./scripts/refresh-gha-creds.sh KrishTalwar03/acs-730coursework staging prod` from Git Bash or WSL, pasting the three current session credential lines when prompted. Never use the old repository-level invocation after migration. Then run `bash scripts/configure-assignment1-github.sh` again; it removes the repository-level copies once it confirms all three environment secrets exist on staging and prod.
5. `admin_cidr` is currently set to the laptop IP shown in the provided screenshot (`142.189.207.231/32`). The assignment security group allows HTTP on port 80 only from that IP, so the web page is reachable from your laptop without opening it to everyone. Update `admin_cidr` in all three `terraform.tfvars` files when the laptop's public IP changes. The existing workstation screenshot already shows SSH port 22 restricted to this `/32`; the assignment web instance does not open SSH.

## Workflow and lifecycle

- Pull requests touching `assignment1/**` run Terraform formatting and validation only.
- A push to `main` first applies staging automatically, then starts the `prod` job. The GitHub `prod` environment must have its required reviewer protection configured for the job to wait for approval.
- Both apply jobs initialize the backend with environment-specific keys: `assignment1/staging/terraform.tfstate` and `assignment1/prod/terraform.tfstate`.
- To destroy an environment, run `terraform init` and `terraform destroy -var-file=terraform.tfvars` from that environment directory using a live Academy session. Destroy staging and prod after collecting evidence. Do not delete state until destroy succeeds.

See `REPORT.md` for the trust-policy example, rationale, and deployment evidence checklist. The AWS Academy credential flow uses session-scoped secrets because the course account does not permit setting up AWS OIDC; the trust policy is a recommendation for a real AWS account, not an assertion that the Academy deployment used OIDC.
