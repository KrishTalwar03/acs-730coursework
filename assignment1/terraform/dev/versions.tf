terraform {
  required_version = "~> 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }

  backend "s3" {
    bucket       = "acs730-tfstate-928670087602"
    key          = "assignment1/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Course     = "ACS730"
      Assignment = "assignment1"
      Owner      = var.owner
    }
  }
}
