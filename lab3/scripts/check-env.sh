cat > lab3/scripts/check-env.sh <<'EOF'
#!/usr/bin/env bash
# check-env.sh -- print the facts a Lab 3 run depends on.
set -euo pipefail
echo "terraform: $(terraform version | head -1)"
echo "region: ${AWS_REGION:-unset}"
if [ -z "${AWS_REGION:-}" ]; then
  echo "AWS_REGION is not set"
  exit 1
fi
echo "environment looks sane"
EOF
chmod +x lab3/scripts/check-env.sh
bash -n lab3/scripts/check-env.sh && ./scripts/check-lab.sh lab3
