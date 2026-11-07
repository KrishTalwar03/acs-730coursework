output "vpc_id" {
  description = "ID of the VPC this configuration created."
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "Public subnet IDs, keyed like public_subnets."
  value       = { for key, subnet in aws_subnet.public : key => subnet.id }
}

output "web_public_ip" {
  description = "Web server public IP. LocalStack invents one; it does not route."
  value       = aws_instance.web.public_ip
}

output "web_url" {
  description = "URL to curl after boot, on real AWS only."
  value       = "http://${aws_instance.web.public_ip}/"
}

output "artifact_bucket" {
  description = "Optional bucket name, or null when it was not created."
  value       = one(aws_s3_bucket.artifacts[*].bucket)
}

output "provider_target" {
  description = "Which endpoint this run actually talked to."
  value       = local.provider_target
}
