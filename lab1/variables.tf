variable "aws_region"{
    description = "value of the region"
    type = string
    default = "us-east-1"
}
variable "vpc_name"{
    description = "Name of the VPC"
    type = string
    default = "my-vpc"
}

variable "public_subnet_name"{
    description = "Name of the public subnet"
    type = string
    default = "public-subnet"
}
variable "public_subnet_count"{
    description = "Number of public subnet"
    type = number
    default = 2
}

variable "private_subnet_count"{
    description = "Number of private subnet"
    type = number
    default = 2
}

variable "public_subnet_cidr_blocks"{
    description = "CIDR blocks for public subnet"
    type = list(string)
    default = ["10.0.1.0/24","10.0.2.0/24"]
}

variable "private_subnet_cidr_blocks"{
    description = "CIDR blocks for private subnet"
    type = list(string)
    default = ["10.0.3.0/24","10.0.4.0/24"]
}

variable "availability_zones"{
    description = "Availability zones"
    type = list(string)
    default = ["us-east-1a"]
}

variable "vpc_cidr_block"{
    description = "CIDR block for VPC"
    type = string
    default = "10.0.0.0/16"
}

variable "resource_tags"{
    description = "Tags to set on the resources"
    type = map(string)
    default = {
        Terraform = "true"
        Environment = "dev"
        project = "coursera-lab"
    }
}
