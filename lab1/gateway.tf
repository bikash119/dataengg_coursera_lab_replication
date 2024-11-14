resource "aws_internet_gateway" "lab1" {
  vpc_id = aws_vpc.lab1.id

  tags = {
    Name = "Lab1 Internet Gateway"
  }
}

resource "aws_route_table" "ig_route_a" {
  vpc_id = aws_vpc.lab1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab1.id
  }

  tags = {
    Name = "Internet Route Table AZ-A"
  }
}

resource "aws_route_table" "ig_route_b" {
  vpc_id = aws_vpc.lab1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab1.id
  }

  tags = {
    Name = "Internet Route Table AZ-B"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.ig_route_a.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.ig_route_b.id
}
## Create NAT Gateway to allow outbound internet traffic from private subnet a
resource "aws_nat_gateway" "lab1_a" {
  connectivity_type = "private"
  subnet_id         = aws_subnet.public_subnet_a.id
  tags = {
    Name = "Lab1 NAT Gateway A"
  }
}

## Create NAT Gateway to allow outbound internet traffic from private subnet b
resource "aws_nat_gateway" "lab1_b" {
  connectivity_type = "private"
  subnet_id         = aws_subnet.public_subnet_b.id
  tags = {
    Name = "Lab1 NAT Gateway B"
  }
}

## Allocate Elastic IP for NAT Gateway A
resource "aws_eip" "nat_eip_a" { 
  vpc = true
}

## Allocate Elastic IP for NAT Gateway B
resource "aws_eip" "nat_eip_b" {
  vpc = true
}

resource "aws_route_table" "private_a"{
  vpc_id = aws_vpc.lab1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.lab1_a.id
  }
  tags = {
    Name = "Private Route Table AZ-A"
  }
}

resource "aws_route_table" "private_b"{
  vpc_id = aws_vpc.lab1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.lab1_b.id
  }
  tags = {
    Name = "Private Route Table AZ-B"
  }
}

resource "aws_route_table_association" "private_subnet_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id =  aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_subnet_b"{
  subnet_id       = aws_subnet.private_subnet_b.id
  route_table_id  = aws_route_table.private_b.id
}