# Required evidence checklist

The professor's guide requires these exact filenames in this directory. Capture each item from the real GitHub/AWS Academy run, keep secret values hidden, and do not create placeholder files that imply a step succeeded.

| File | Capture point |
| --- | --- |
| `backend-state-keys.txt` | After dev, staging, and prod each initialize/apply; list the three distinct S3 state keys. |
| `environments.json` | After creating the `staging` and `prod` GitHub Environments and their protection settings. |
| `secrets-scope.txt` | Immediately after all three credential secrets exist in both environments and repository-level copies are deleted. Include names/scopes only, never values. |
| `prod-approval-pending.png` | While the prod workflow job is waiting for approval, before approving it. |
| `prod-approval-approved.png` | Immediately after approving prod and confirming the job proceeds. |
| `staging-apply.txt` | After the merge-triggered staging apply succeeds; save the workflow log, not just its URL. |
| `prod-apply.txt` | After the approved production apply succeeds; save the workflow log. |
| `ssm-parameter.txt` | After Terraform reads the SecureString; show the parameter name/type and ARN, never its value. |
| `cloudwatch-alarm.json` | After several metric periods; include the alarm state and CPU metric. The state must not be `INSUFFICIENT_DATA`. |
| `cloudwatch-alarm.png` | Screenshot of the same alarm state as the JSON. |
| `destroy-complete.txt` | Last: capture destroy output for dev, staging, and prod plus the course cleanup-check output showing nothing remains. |

All files must be non-empty and committed to `main`. Do not fabricate deployment evidence: collect it only after the corresponding action has actually succeeded.
