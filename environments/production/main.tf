variable "build_env" {}

variable "aws_region" {}
variable "aws_profile" {}
variable "aws_shared_credentials_file" {}
variable "aws_auth_token" {}
variable "aws_auth_secret" {}

variable "domain" {}
variable "prefix" {}

variable "db_name" {}
variable "db_user" {}
variable "db_password" {}

module "modules" {
  source = "../../modules/ecs"
  build_env = var.build_env
  prefix = var.prefix
  domain = var.domain
  aws_region  = var.aws_region
  aws_auth_token = var.aws_auth_token
  aws_auth_secret = var.aws_auth_secret
  db_name = var.db_name
  db_user = var.db_user
  db_password = var.db_password
}

provider "aws" {
  version = "~> 2.0"
  shared_credentials_file = var.aws_shared_credentials_file
  region  = var.aws_region
  profile = var.aws_profile
}