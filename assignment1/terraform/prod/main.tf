module "web_stack" {
  source = "../modules/web_stack"

  environment                       = var.environment
  owner                             = var.owner
  project                           = var.project
  vpc_cidr                          = var.vpc_cidr
  public_subnet_cidr                = var.public_subnet_cidr
  http_cidrs                        = [var.admin_cidr]
  instance_type                     = var.instance_type
  application_secret_parameter_name = var.application_secret_parameter_name
}
