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
# variables

# outputs