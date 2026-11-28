#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-KrishTalwar03/acs-730coursework}"
REVIEWER_LOGIN="${2:-}"
command -v gh >/dev/null || { echo "Install GitHub CLI and run 'gh auth login' first." >&2; exit 1; }
gh auth status >/dev/null

for environment in dev staging prod; do
  gh api --method PUT "repos/$REPO/environments/$environment" --silent
done

# Restrict production deployment jobs to the main branch.
gh api --method PUT "repos/$REPO/environments/prod" \
  -F 'deployment_branch_policy[protected_branches]=false' \
  -F 'deployment_branch_policy[custom_branch_policies]=true' \
  --silent

if [[ -n "$REVIEWER_LOGIN" ]]; then
  REVIEWER_ID="$(gh api "users/$REVIEWER_LOGIN" --jq '.id')"
  gh api --method PUT "repos/$REPO/environments/prod" \
    -F 'deployment_branch_policy[protected_branches]=false' \
    -F 'deployment_branch_policy[custom_branch_policies]=true' \
    -F 'reviewers[][type]=User' \
    -F "reviewers[][id]=$REVIEWER_ID" \
    -F 'prevent_self_review=false' \
    --silent
fi

POLICY_NAMES="$(gh api "repos/$REPO/environments/prod/deployment-branch-policies" --jq '.branch_policies[]?.name' 2>/dev/null || true)"
if ! grep -Fxq main <<<"$POLICY_NAMES"; then
  gh api --method POST "repos/$REPO/environments/prod/deployment-branch-policies" \
    -f name=main -f type=branch --silent
fi

all_environment_secrets_exist=true
for environment in staging prod; do
  NAMES="$(gh secret list --repo "$REPO" --env "$environment" --json name --jq '.[].name')"
  for secret in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN; do
    if ! grep -Fxq "$secret" <<<"$NAMES"; then
      all_environment_secrets_exist=false
    fi
  done
done

if $all_environment_secrets_exist; then
  for secret in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN; do
    if gh secret list --repo "$REPO" --json name --jq '.[].name' | grep -Fxq "$secret"; then
      gh secret delete "$secret" --repo "$REPO"
    fi
  done
  echo "Environment secrets are present and repository-level AWS credential copies were removed."
else
  echo "Environments and the prod main-only branch policy are configured."
  echo "Next refresh the session credentials into both environments:"
  echo "  ./scripts/refresh-gha-creds.sh $REPO staging prod"
  echo "Then rerun this script to remove repository-level credential copies."
fi

echo "Set at least one required reviewer for prod in GitHub Settings > Environments > prod."
if [[ -z "$REVIEWER_LOGIN" ]]; then
  echo "Or rerun this script with an eligible GitHub username as the second argument."
  echo "Enable Prevent self-review so the person starting a deployment cannot approve it."
else
  echo "Configured $REVIEWER_LOGIN as a prod reviewer. Self-review is allowed so this account can approve its own deployment."
fi
