variable "aws_region" {
  description = "AWS region donde se creará la tabla DynamoDB"
  type        = string
  default     = "us-east-1"
}

variable "table_name" {
  description = "Nombre de la tabla DynamoDB"
  type        = string
  default     = "Items"
}
variable "cidr_vpc" {
  type    = string
  default = "10.10.0.0/16"
}

variable "subnet_private1_cidr" {
  type    = string
  default = "10.10.10.0/24"
}

variable "subnet_private2_cidr" {
  type    = string
  default = "10.10.11.0/24"
}

variable "deployer_iam" {
  type    = string
  default = "arn:aws:iam::024848464519:user/terraform-deploy"
}
variable "deployer_github_role" {
  type    = string
  default = "arn:aws:iam::024848464519:role/deployment-role-github"
}

variable "instances" {
  type = map(object({
    subnet_id = string
    name      = string
  }))
}
