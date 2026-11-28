output "vpc_id" {
  value       = module.web_stack.vpc_id
  description = "Staging VPC ID."
}

output "web_instance_id" {
  value       = module.web_stack.web_instance_id
  description = "Staging web instance ID."
}

output "web_public_ip" {
  value       = module.web_stack.web_public_ip
  description = "Staging web instance public IP."
}

output "web_url" {
  value       = module.web_stack.web_url
  description = "Staging web page URL."
}

output "cpu_alarm_name" {
  value       = module.web_stack.cpu_alarm_name
  description = "Staging CPU alarm name."
}

output "application_parameter_arn" {
  value       = module.web_stack.application_parameter_arn
  description = "ARN of the SSM application parameter read by Terraform."
}
