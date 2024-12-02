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
  region = var.aws_region
}
data "aws_availability_zones" "available" {
  state = "available"
}
# resources

resource "aws_security_group" "allow_ssh" {
  name              = "allow_ssh"
  description       = "Allow SSH inbound traffic and all outbound traffic"
  vpc_id            = module.vpc.vpc_id

  tags = var.resource_tags
}
resource "aws_vpc_security_group_egress_rule" "ssh_egress" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
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
  name                   = "allow_mysql"
  description            = "Allow tcp inbound traffic and all outbound traffic"
  vpc_id                 = module.vpc.vpc_id
  revoke_rules_on_delete = true
  tags = {
    Name = "allow_mysql"
  }
}
resource "aws_vpc_security_group_egress_rule" "mysql_sg_egress" {
  security_group_id = aws_security_group.mysql_sg.id
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "allow_mysql_ipv4" {
  security_group_id = aws_security_group.mysql_sg.id
  cidr_ipv4         = module.vpc.public_subnets_cidr_blocks[0]
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
  
}

resource "aws_vpc_security_group_ingress_rule" "self_reference_mysql" {
  security_group_id              = aws_security_group.mysql_sg.id
  referenced_security_group_id   = aws_security_group.mysql_sg.id
  from_port                      = 0
  ip_protocol                    = "tcp"
  to_port                        = 65535
}


resource "aws_db_subnet_group" "lab1" {
  name       = "private_subnet_group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "My DB subnet group"
  }
}