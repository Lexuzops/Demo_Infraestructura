variable "aws_region" {
  description = "AWS region donde se creará la tabla DynamoDB"
  type        = string
  default     = "us-east-1"
}

variable "bucket_terraform" {
  description = "Nombre del bucket S3 para el estado de Terraform"
  type        = string
  default     = "app-test-terraform-state-1234567890"
}

variable "dynamodb_lock_table" {
  description = "Nombre de la tabla DynamoDB para el lock de Terraform"
  type        = string
  default     = "terraform-locks"
}