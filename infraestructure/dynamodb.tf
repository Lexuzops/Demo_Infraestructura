resource "aws_dynamodb_table" "items" {
  name         = var.table_name
  billing_mode = "PROVISIONED" # Pensado para free tier
  hash_key     = "id"

  # Capacidad muy baja para encajar en el free tier (25 RCUs / 25 WCUs gratis)
  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "id"
    type = "S"
  }

  # Opcional: etiquetas útiles
  tags = {
    Project     = "devops-test"
    ManagedBy   = "terraform"
  }
}
