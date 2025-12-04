resource "aws_vpc" "app_test" {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "app-test"
  }
}

# Public subnet requires an Internet Gateway
resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app_test.id

  tags = {
    Name = "app-test-igw"
  }
}
