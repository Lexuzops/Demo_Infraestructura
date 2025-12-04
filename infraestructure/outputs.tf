output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB creada"
  value       = aws_dynamodb_table.items.name
}

output "dynamodb_table_arn" {
  description = "ARN de la tabla DynamoDB"
  value       = aws_dynamodb_table.items.arn
}

output "vpc_id" {
  value = aws_vpc.app_test.id
}

output "public_subnet_az1_id" {
  value = aws_subnet.public_az1.id
}

output "private_subnet1_id" {
  value = aws_subnet.private_az1.id
}

output "private_subnet2_id" {
  value = aws_subnet.private_az2.id
}

# output "ec2_public_ip" {
#   description = "IP pública de la EC2 app-test"
#   value       = aws_instance.app_server.public_ip
# }

output "alb_dns_name" {
  description = "DNS público del ALB"
  value       = aws_lb.app_alb.dns_name
}