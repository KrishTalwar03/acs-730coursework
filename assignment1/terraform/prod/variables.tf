variable "aws_region" {
  description = "AWS region for production resources."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "owner" {
  description = "Seneca username used for resource tagging."
  type        = string
  default     = "ktalwar3"
}

variable "project" {
  description = "Prefix used in production resource names."
  type        = string
  default     = "acs730-a1"
}

variable "vpc_cidr" {
  description = "Production VPC CIDR."
  type        = string
  default     = "10.53.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Production public subnet CIDR."
  type        = string
  default     = "10.53.1.0/24"
}

variable "admin_cidr" {
  description = "Laptop public IP CIDR allowed to reach the web server. Update when your public IP changes."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.admin_cidr)) && can(regex("/32$", var.admin_cidr))
    error_message = "admin_cidr must be one public IPv4 address ending in /32."
  }
}

variable "instance_type" {
  description = "EC2 instance size for production."
  type        = string
  default     = "t3.micro"
}

variable "application_secret_parameter_name" {
  description = "Existing SSM SecureString parameter read by the module."
  type        = string
  default     = "/acs730/assignment1/application-secret"
}
