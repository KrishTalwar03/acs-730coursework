output "vpc_id" {
  description = "ID of the environment VPC."
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the environment public subnet."
  value       = aws_subnet.public.id
}

output "web_instance_id" {
  description = "ID of the web server EC2 instance."
  value       = aws_instance.web.id
}

output "web_public_ip" {
  description = "Public IPv4 address of the web server."
  value       = aws_instance.web.public_ip
}

output "web_url" {
  description = "HTTP URL of the deployed web server."
  value       = "http://${aws_instance.web.public_ip}/"
}

output "cpu_alarm_name" {
  description = "CloudWatch alarm watching this instance's CPUUtilization metric."
  value       = aws_cloudwatch_metric_alarm.high_cpu.alarm_name
}

output "application_parameter_arn" {
  description = "ARN of the application SecureString Terraform reads from SSM."
  value       = data.aws_ssm_parameter.application_secret.arn
}
