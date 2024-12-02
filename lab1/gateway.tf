## Create NAT Gateway to allow outbound internet traffic from private subnet a
resource "aws_nat_gateway" "lab1_a" {
  connectivity_type = "public"
  subnet_id         = module.vpc.public_subnets[0]
  allocation_id = aws_eip.nat_eip_a.id

  tags = {
    Name = "Lab1 NAT Gateway A"
  }
}

## Create NAT Gateway to allow outbound internet traffic from private subnet b
resource "aws_nat_gateway" "lab1_b" {
  connectivity_type = "public"
  subnet_id         = module.vpc.public_subnets[1]
  allocation_id = aws_eip.nat_eip_b.id
  tags = {
    Name = "Lab1 NAT Gateway B"
  }
}

## Allocate Elastic IP for NAT Gateway A
resource "aws_eip" "nat_eip_a" { 
  domain = "vpc"
}

## Allocate Elastic IP for NAT Gateway B
resource "aws_eip" "nat_eip_b" {
  domain = "vpc"
}

resource "aws_route_table" "private_a"{
  vpc_id = module.vpc.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.lab1_a.id
  }
  tags = {
    Name = "Private Route Table AZ-A"
  }
}

resource "aws_route_table" "private_b"{
  vpc_id = module.vpc.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.lab1_b.id
  }
  tags = {
    Name = "Private Route Table AZ-B"
  }
}