# === Public Subnet in AZ1 ===
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.app_test.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "app-test-public-1a"
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.app_test.id
  cidr_block              = "10.10.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "app-test-public-1b"
  }
}
# Public subnet needs a public route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.app_test.id

  tags = {
    Name = "app-test-public-rt"
  }
}

resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.app_igw.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "app-test-nat-eip"
  }
}

# NAT Gateway (en la subnet pública AZ1)
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_az1.id 

  tags = {
    Name = "app-test-nat-gateway"
  }

  depends_on = [aws_internet_gateway.app_igw]
}


# Ruta de salida a Internet desde private subnets hacia NAT Gateway
resource "aws_route" "nat_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}


resource "aws_route_table_association" "public_assoc1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public_rt.id
}

# === Private Subnets in 2 AZs different ===
resource "aws_subnet" "private_az1" {
  vpc_id            = aws_vpc.app_test.id
  cidr_block        = var.subnet_private1_cidr
  availability_zone = "us-east-1a"

  tags = {
    Name = "app-test-private-1a"
  }
}

resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.app_test.id
  cidr_block        = var.subnet_private2_cidr
  availability_zone = "us-east-1b"

  tags = {
    Name = "app-test-private-1b"
  }
}

# Private route table (sin internet)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.app_test.id

  tags = {
    Name = "app-test-private-rt"
  }
}

resource "aws_route_table_association" "private_assoc1" {
  subnet_id      = aws_subnet.private_az1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc2" {
  subnet_id      = aws_subnet.private_az2.id
  route_table_id = aws_route_table.private_rt.id
}
