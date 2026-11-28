variable "environment" {
  description = "Deployment environment name used in resource names and tags."
  type        = string
}

variable "owner" {
  description = "Course owner tag value."
  type        = string
}

variable "project" {
  description = "Short project prefix for AWS resource names."
  type        = string
  default     = "acs730-a1"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block reserved for this environment's VPC."
  type        = string
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR contained within vpc_cidr."
  type        = string
}

variable "http_cidrs" {
  description = "IPv4 CIDR ranges allowed to access the HTTP web server."
  type        = list(string)
  validation {
    condition     = length(var.http_cidrs) > 0 && alltrue([for cidr in var.http_cidrs : can(cidrnetmask(cidr))])
    error_message = "http_cidrs must contain one or more valid IPv4 CIDR blocks."
  }
}

variable "instance_type" {
  description = "EC2 instance type for the web server."
  type        = string
  default     = "t3.micro"
  validation {
    condition     = contains(["t3.micro", "t3.small"], var.instance_type)
    error_message = "Use t3.micro or t3.small to stay within the course budget."
  }
}

variable "application_secret_parameter_name" {
  description = "Name of the pre-created SSM SecureString parameter read by this module."
  type        = string
  default     = "/acs730/assignment1/application-secret"
}
