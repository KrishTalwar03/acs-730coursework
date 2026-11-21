# Lab 6: Configuration Management and Golden AMI

The GitHub-hosted runner reaches the targets through AWS Systems Manager Session Manager using temporary Academy credentials, so no long-lived SSH key or inbound port 22 is needed. A second Ansible run with `changed=0` proves the role checked the hosts and found their state already matched the desired configuration. Deregistering an AMI does not delete its backing EBS snapshot, so the snapshot must be deleted separately.

## Boot-to-ready comparison

| Path | Time | Includes |
|---|---:|---|
| Converge on boot | 128 seconds | Instance replacement, SSM registration, package installation, and service startup |
| Golden AMI | 28 seconds | Instance launch, boot, and web service startup |

The golden AMI is my choice for repeated launches because configuration is done once during the bake; I would use converge on boot for occasional launches where avoiding image rebuilds matters. A golden AMI can become stale and needs a rebuild cadence, while converge on boot depends on package repositories being available. The SSM transfer bucket and `ansible_aws_ssm_region` are both in `us-east-1`.

## Experiments

### Unguarded shell command

I predicted an unguarded shell command would report a change on every run because Ansible cannot determine the command's desired state. Both runs reported `changed=1` on both hosts; adding `creates: /opt/acs730-web/logs` let Ansible skip the command once that path existed.

### Changing the template variable

I predicted changing `site_title` would change the landing page and systemd unit templates on both hosts, and that the unit change would trigger the restart handler. The run showed those template changes and the handler; after restoring the default title, I reran the playbook and confirmed the second run returned to `changed=0`.
