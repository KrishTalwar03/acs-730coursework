#!/usr/bin/env bash
set -euo pipefail

PARAMETER_NAME="/acs730/assignment1/application-secret"
AWS_REGION="${AWS_REGION:-us-east-1}"

command -v aws >/dev/null || { echo "Install and configure AWS CLI first." >&2; exit 1; }
aws sts get-caller-identity --query Account --output text >/dev/null

read -r -s -p "Enter a placeholder application secret to store as an SSM SecureString: " APP_SECRET
printf '\n'
if [[ -z "$APP_SECRET" ]]; then
  echo "The parameter value cannot be empty." >&2
  exit 1
fi

# The value is entered silently and never written to the repository or printed.
aws ssm put-parameter \
  --name "$PARAMETER_NAME" \
  --type SecureString \
  --overwrite \
  --value "$APP_SECRET" \
  --region "$AWS_REGION" \
  --query 'Version' \
  --output text >/dev/null
unset APP_SECRET
echo "Stored $PARAMETER_NAME as an SSM SecureString in $AWS_REGION."
