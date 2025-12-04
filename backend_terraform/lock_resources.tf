
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }


}

provider "aws" {
  region = var.aws_region
}
#S3 para el archivo tfstate
resource "aws_s3_bucket" "tf_state" {
  bucket = var.bucket_terraform
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_enc" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}


#Tabla de dybamo para lock de terraform
resource "aws_dynamodb_table" "tf_locks" {
  name         = var.dynamodb_lock_table
  billing_mode = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
