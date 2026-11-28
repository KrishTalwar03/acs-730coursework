output "vpc_id" {
  value       = module.web_stack.vpc_id
  description = "Dev VPC ID."
}

output "web_instance_id" {
  value       = module.web_stack.web_instance_id
  description = "Dev web instance ID."
}

output "web_public_ip" {
  value       = module.web_stack.web_public_ip
  description = "Dev web instance public IP."
}

output "web_url" {
  value       = module.web_stack.web_url
  description = "Dev web page URL."
}

output "cpu_alarm_name" {
  value       = module.web_stack.cpu_alarm_name
  description = "Dev CPU alarm name."
}
