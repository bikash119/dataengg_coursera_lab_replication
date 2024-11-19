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
      max_price = 0.0032
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
    yum install -y aws-cli

    # Create script directory
    mkdir -p /opt/mysql-loader
    
    # Create the loader script
    cat << 'SCRIPT' > /opt/mysql-loader/load_data.sh
    #!/bin/bash
    
    # Download SQL file from S3
    aws s3 cp s3://aws_s3_bucket.scripts.id/aws_s3_object.mysql_data_script.id /opt/mysql-loader/data.sql
    
    # Execute SQL file
    mysql \
      -h aws_db_instance.default.endpoint \
      -u foo \
      -p foobarbaz \
      mydb \
      < /opt/mysql-loader/data.sql
    
    # Clean up
    rm -f /opt/mysql-loader/data.sql
    SCRIPT
    
    # Make script executable
    chmod +x /opt/mysql-loader/load_data.sh
    
    # Run the loader script and log output
    /opt/mysql-loader/load_data.sh > /opt/mysql-loader/load.log 2>&1
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
      max_price = 0.0032
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