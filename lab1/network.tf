## Create a VPC
resource "aws_vpc" "lab1" {
  cidr_block = "10.0.0.0/16"
}

## Create 4 subnets. 2 Private and 2 Public. One of each availability zone.
resource "aws_subnet" "private_subnet_a" {
  vpc_id     = aws_vpc.lab1.id
  cidr_block = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Private Subnet AZ A"
  }
}
resource "aws_subnet" "private_subnet_b" {
  vpc_id     = aws_vpc.lab1.id
  cidr_block = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "Private Subnet AZ B"
  }
}
resource "aws_subnet" "public_subnet_a" {
  vpc_id     = aws_vpc.lab1.id
  cidr_block = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Public Subnet AZ A"
  }
}
resource "aws_subnet" "public_subnet_b" {
  vpc_id     = aws_vpc.lab1.id
  cidr_block = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "Public Subnet AZ B"
  }
}
