resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_security_group" "rds_sg" {
  name_prefix = "rds-"
  description = "Security group for RDS"
  vpc_id = aws_vpc.my_vpc.id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_group_id = aws_security_group.rds_sg.id
    source_security_group_id = aws_security_group.ec2_to_rds_sg.id
  }
}

resource "aws_security_group" "ec2_to_rds_sg" {
  name        = "ec2-to-rds-sg"
  description = "Security group for EC2 instances to connect to RDS"

  vpc_id = aws_vpc.my_vpc.id

  # Allow inbound traffic from the EC2 instances to the RDS instance
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.rds_sg.id]
  }
}


resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]

  tags = {
    Name = "My DB Subnet Group"
  }
}

# Define an AWS Auto Scaling Group (ASG) for the EC2 instance cluster
resource "aws_launch_configuration" "ec2_cluster_config" {
  name_prefix                 = "ec2-cluster-config-"
  image_id                    = "ami-0005e0cfe09cc9050"
  instance_type               = "t2.micro"  
  key_name                    = "jjtech-jocelyne"
  security_groups             = [aws_security_group.ec2_to_rds_sg.id]
  user_data                   = <<-EOF
                                  #!/bin/bash
                                  EOF
}

resource "aws_autoscaling_group" "ec2_cluster" {
  launch_configuration = aws_launch_configuration.ec2_cluster_config.name
  min_size            = 2  # Minimum number of instances in the cluster
  max_size            = 5  # Maximum number of instances in the cluster
  desired_capacity    = 2  # Desired number of instances in the cluster
  vpc_zone_identifier = [aws_subnet.subnet_a.id]
}























