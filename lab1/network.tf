## Create a VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.7.0"
  azs             = data.aws_availability_zones.available.names
  cidr            = var.vpc_cidr_block
  private_subnets = slice(var.private_subnet_cidr_blocks, 0, var.private_subnet_count)
  public_subnets  = slice(var.public_subnet_cidr_blocks, 0, var.public_subnet_count)
  name            = var.resource_tags["project"]
}


# Create a route from private subnets to the NAT Gateway
resource "aws_route" "private_subnet_to_nat_gateway" {
  route_table_id         = module.vpc.private_route_table_ids[0]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.lab1_a.id
}