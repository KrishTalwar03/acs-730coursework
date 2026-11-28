# Evidence to capture

Save genuine screenshots in this directory after the GitHub and AWS Academy actions complete. Do not create or edit screenshots to imply a deployment succeeded.

1. GitHub Settings > Environments: show `staging` has the three AWS secrets and auto-deployment settings; show `prod` has the three AWS secrets, `main` deployment branch policy, and at least one required reviewer. Keep secret values hidden.
2. GitHub Actions: show the main-branch run completed staging and that the production job paused for approval, then show the approved production job completed.
3. AWS: show the running staging and prod resources, web URL response, Parameter Store parameter name/type with the value hidden, and CloudWatch CPU alarm configuration.
4. After cleanup, capture successful Terraform destroys for staging and prod and verify no resources tagged `Assignment=assignment1` remain.

Record the workflow run link, commit SHA, deployment time, and cleanup result in `REPORT.md` after observing them.
