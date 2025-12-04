# Bucket S3
resource "aws_s3_bucket" "zip_bucket" {
  bucket = "test-bucket-con-zip-1234567890"

  tags = {
    Name = "bucket-con-zip"
  }
}

# Objeto ZIP dentro del bucket
resource "aws_s3_object" "zip_file" {
  bucket = aws_s3_bucket.zip_bucket.id
  key    = "miapp.zip"

  # Ruta al archivo ZIP en tu máquina
  source = "../miapp.zip"

  # Para que Terraform detecte cambios en el archivo
  etag = filemd5("../miapp.zip")

  content_type = "application/zip"
}

data "aws_iam_policy_document" "zip_bucket_policy" {

  statement {
    sid    = "AllowEC2RoleReadOnly"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.ec2_instance_role.arn]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.zip_bucket.arn,
      "${aws_s3_bucket.zip_bucket.arn}/*",
    ]
  }

  statement {
    sid    = "AllowSpecificUserWriteDelete"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.deployer_iam]
    }

    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.zip_bucket.arn,
      "${aws_s3_bucket.zip_bucket.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "zip_bucket_policy" {
  bucket = aws_s3_bucket.zip_bucket.id
  policy = data.aws_iam_policy_document.zip_bucket_policy.json
}
