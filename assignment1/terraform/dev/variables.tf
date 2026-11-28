variable "aws_region" {
  description = "AWS region for dev resources."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Seneca username used for resource tagging."
  type        = string
  default     = "ktalwar3"
}

variable "project" {
  description = "Prefix used in dev resource names."
  type        = string
  default     = "acs730-a1"
}

variable "vpc_cidr" {
  description = "Dev VPC CIDR."
  type        = string
  default     = "10.51.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Dev public subnet CIDR."
  type        = string
  default     = "10.51.1.0/24"
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
  description = "EC2 instance size for dev."
  type        = string
  default     = "t3.micro"
}

variable "application_secret_parameter_name" {
  description = "Existing SSM SecureString parameter read by the module."
  type        = string
  default     = "/acs730/assignment1/application-secret"
}
