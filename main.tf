
# Create a VPC
resource "aws_vpc" "cloudgen_vpc" {
  cidr_block = "10.0.0.0/16"
    enable_dns_support   = true
  enable_dns_hostnames = true
}

# Create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.cloudgen_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-2a"  # Replace with your desired availability zone
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.cloudgen_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2b"  # Replace with your desired availability zone
  map_public_ip_on_launch = true
}

# Create an internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.cloudgen_vpc.id
}

# Attach the internet gateway to the VPC
resource "aws_internet_gateway_attachment" "attach_gw" {
  internet_gateway_id = aws_internet_gateway.gw.id
  vpc_id              = aws_vpc.cloudgen_vpc.id
}


# Create a security group for the load balancer
resource "aws_security_group" "lb_sg" {
  vpc_id = aws_vpc.cloudgen_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

# # Create a security group for the EC2 instances
resource "aws_security_group" "cloudgen_ec2_sg" {
  vpc_id = aws_vpc.cloudgen_vpc.id
  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "ssh from ec2"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Create an application load balancer
resource "aws_lb" "cloudgen_lb" {
  name               = "cloudgen-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]
}

# Create an auto-scaling group
resource "aws_autoscaling_group" "cloudgen_asg" {
  name                      = "cloudgen_asg"
  min_size                  = 2
  max_size                  = 5
  desired_capacity          = 2
  health_check_type         = "EC2"
  vpc_zone_identifier       = [aws_subnet.public_subnet.id]
  target_group_arns         = [aws_lb_target_group.cloudgen_vpc.arn]
  launch_template {
    id      = aws_launch_template.cloud_gen_lt.id
    version = "$Latest"
  }
}

# Create a launch template for the auto-scaling group
resource "aws_launch_template" "cloud_gen_lt" {
  name                   = "cloudgen-launch-template"
  image_id               = var.ami # Add your ami ID here
  instance_type          = var.instance_type       # Replace with your desired instance type
  vpc_security_group_ids = [aws_security_group.cloudgen_ec2_sg.id]
}

# Create a target group for the load balancer
resource "aws_lb_target_group" "cloudgen_vpc" {
  name     = "cloudgen-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.cloudgen_vpc.id
}


# Create an RDS instance
resource "aws_db_instance" "cloudgen-rds" {
  identifier              = "cloudgen"
  allocated_storage       = 20
  engine                  = "mysql"          # Replace with your desired database engine
  engine_version          = "8.0.33"         # Replace with your desired engine version
  instance_class          = var.instance_class   # Replace with your desired instance type
  username                = var.username   # Replace with your desired database username
  password                = var.password   # Replace with your desired database password
  publicly_accessible     = false
  db_subnet_group_name    = aws_db_subnet_group.cloudgen_db_subnet.name
  vpc_security_group_ids  = [aws_security_group.cloudgen_ec2_sg.id]
  skip_final_snapshot     = true
}

# Create a database subnet group
resource "aws_db_subnet_group" "cloudgen_db_subnet" {
  name       = "cloudgen-subnet-group"
  subnet_ids = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]
}
