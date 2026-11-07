data "aws_ami" "al2023" {
  count = var.use_localstack ? 0 : 1

  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }
}

locals {
  ami_id           = var.use_localstack ? var.localstack_ami_id : data.aws_ami.al2023[0].id
  first_subnet_key = keys(local.public_subnets)[0]
}

resource "aws_instance" "web" {
  ami                    = local.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[local.first_subnet_key].id
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOT
    #!/bin/bash
    set -euo pipefail
    dnf -y install nginx
    echo "<h1>ACS730 Lab 5 - ${local.name}</h1>" > /usr/share/nginx/html/index.html
    systemctl enable --now nginx
  EOT

  depends_on = [aws_route_table_association.public]
  tags       = merge(local.common_tags, { Name = "${local.name}-web" })
}

resource "aws_s3_bucket" "artifacts" {
  count = var.create_artifact_bucket ? 1 : 0

  bucket        = "${local.name}-artifacts"
  force_destroy = true
  tags          = merge(local.common_tags, { Name = "${local.name}-artifacts" })
}
