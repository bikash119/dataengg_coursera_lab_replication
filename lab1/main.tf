# Providers and settings

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
data "aws_availability_zones" "available" {
  state = "available"
}
# resources
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

## Create a IG to allow inbound internet traffic into public subnet
resource "aws_internet_gateway" "lab1" {
  vpc_id = aws_vpc.lab1.id

  tags = {
    Name = "Lab1 Internet Gateway"
  }
}

resource "aws_route_table" "ig_route" {
  vpc_id = aws_vpc.lab1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab1.id
  }

  tags = {
    Name = "ig_route"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.ig_route.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.ig_route.id
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
    Name = "Lab1 NAT Gateway A"
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

resource "aws_route_table" "private_subnets"{
  vpc_id = aws_vpc.lab1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.lab1_a.id
  }

  tags = {
    Name = "private_subnets"
  }
}

resource "aws_route_table_association" "private_subnet_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id =  aws_route_table.private_subnets.id
}

resource "aws_route_table_association" "private_subnet_b"{
  subnet_id       = aws_subnet.private_subnet_b.id
  route_table_id  = aws_route_table.private_subnets.id
}
## Create SG to allow inbound internet traffic from IG to resources in public subnet
resource "aws_security_group" "allow_ssh" {
  name              = "allow_ssh"
  description       = "Allow SSH inbound traffic and all outbound traffic"
  vpc_id            = aws_vpc.lab1.id

  tags = {
    Name = "allow_ssh"
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

data "aws_ec2_managed_prefix_list" "ec2_instance_connect" {
  name = "com.amazonaws.us-east-1.ec2-instance-connect"  # Replace region if not us-east-1
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  prefix_list_id   = data.aws_ec2_managed_prefix_list.ec2_instance_connect.id

}
resource "aws_security_group" "mysql_sg" {
  name        = "allow_mysql"
  description = "Allow tcp inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.lab1.id

  tags = {
    Name = "allow_mysql"
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_mysql_ipv4" {
  security_group_id = aws_security_group.mysql_sg.id
  cidr_ipv4         = aws_subnet.public_subnet_a.cidr_block
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
}

resource "aws_db_subnet_group" "lab1" {
  name       = "private_subnet_group"
  subnet_ids = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]

  tags = {
    Name = "My DB subnet group"
  }
}
resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.lab1.name
  vpc_security_group_ids = [aws_security_group.mysql_sg.id]
}

data "aws_ami" "bastion_host" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}

resource "aws_instance" "bastion_host" {
  ami = "ami-0dbaf1a909228f3d5"
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = 0.0031
    }
  }
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public_subnet_a.id
  associate_public_ip_address = true
  availability_zone = data.aws_availability_zones.available.names[0]
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y mysql
    sudo yum install -y ec2-instance-connect
    EOF
  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  tags = {
    Name = "Bastion Host"
  }
}

resource "aws_instance" "bastion_host_b" {
  ami = "ami-0dbaf1a909228f3d5"
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = 0.0031
    }
  }
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public_subnet_b.id
  associate_public_ip_address = true
  availability_zone = data.aws_availability_zones.available.names[1]
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y mysql
    sudo yum install -y ec2-instance-connect
    EOF
  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  tags = {
    Name = "Bastion Host b"
  }
}

# variables

# outputs