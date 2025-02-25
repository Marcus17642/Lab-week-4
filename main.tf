# Configure the version of the AWS provider plugin
terraform {
  required_providers {
    aws = {  # Specify the AWS provider
      source  = "hashicorp/aws"  # Source location of the provider
      version = "~> 5.0"  # Use version 5.0 or any compatible newer version
    }
  }
}

# Configure the AWS Provider with the specified region
provider "aws" {
  region = "us-west-2"  # Set the AWS region to US West (Oregon)
}

# Define local variables
locals {
  lab4_marcus = "lab_week_4"  # Local variable for project tagging
}

# Data source to get the most recent Ubuntu 24.04 AMI owned by Amazon
data "aws_ami" "ubuntu" {
  most_recent = true  # Get the most recent AMI
  owners      = ["amazon"]  # AMI owner is Amazon

  filter {
    name   = "name"  # Filter by name
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]  # AMI name pattern
  }
}

# Create a Virtual Private Cloud (VPC)
resource "aws_vpc" "web" {
  cidr_block           = "10.0.0.0/16"  # CIDR block for the VPC
  enable_dns_support   = true  # Enable DNS support
  enable_dns_hostnames = true  # Enable DNS hostnames

  tags = {
    Name    = "project_vpc"  # Tag for the VPC
    Project = local.lab4_marcus  # Project tag using local variable
  }
}

# Create a public subnet within the VPC
resource "aws_subnet" "web" {
  vpc_id                  = aws_vpc.web.id  # Associate with the VPC
  cidr_block              = "10.0.1.0/24"  # CIDR block for the subnet
  availability_zone       = "us-west-2a"  # Specify the availability zone
  map_public_ip_on_launch = true  # Automatically assign public IPs

  tags = {
    Name    = "Web"  # Tag for the subnet
    Project = local.lab4_marcus  # Project tag using local variable
  }
}

# Create an Internet Gateway for the VPC
resource "aws_internet_gateway" "web-gw" {
  vpc_id = aws_vpc.web.id  # Associate with the VPC

  tags = {
    Name    = "Web"  # Tag for the Internet Gateway
    Project = local.lab4_marcus  # Project tag using local variable
  }
}

# Create a route table for the VPC
resource "aws_route_table" "web" {
  vpc_id = aws_vpc.web.id  # Associate with the VPC

  tags = {
    Name    = "web-route"  # Tag for the route table
    Project = local.lab4_marcus  # Project tag using local variable
  }
}

# Add a default route to the route table
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.web.id  # Associate with the route table
  destination_cidr_block = "0.0.0.0/0"  # Route for all traffic
  gateway_id             = aws_internet_gateway.web-gw.id  # Use the Internet Gateway
}

# Associate the route table with the subnet
resource "aws_route_table_association" "web" {
  subnet_id      = aws_subnet.web.id  # Associate with the subnet
  route_table_id = aws_route_table.web.id  # Associate with the route table
}

# Create a security group for the VPC
resource "aws_security_group" "web" {
  name        = "allow_ssh"  # Name of the security group
  description = "allow ssh from home and work"  # Description of the security group
  vpc_id      = aws_vpc.web.id  # Associate with the VPC

  tags = {
    Name    = "Web"  # Tag for the security group
    Project = local.lab4_marcus  # Project tag using local variable
  }
}

# Allow SSH access in the security group
resource "aws_vpc_security_group_ingress_rule" "web-ssh" {
  security_group_id = aws_security_group.web.id  # Associate with the security group
  cidr_ipv4         = "0.0.0.0/0"  # Allow access from anywhere
  from_port         = 22  # SSH port
  to_port           = 22  # SSH port
  ip_protocol       = "tcp"  # Protocol type
}

# Allow HTTP access in the security group
resource "aws_vpc_security_group_ingress_rule" "web-http" {
  security_group_id = aws_security_group.web.id  # Associate with the security group
  cidr_ipv4         = "0.0.0.0/0"  # Allow access from anywhere
  from_port         = 80  # HTTP port
  to_port           = 80  # HTTP port
  ip_protocol       = "tcp"  # Protocol type
}

# Allow all outbound traffic in the security group
resource "aws_vpc_security_group_egress_rule" "web-egress" {
  security_group_id = aws_security_group.web.id  # Associate with the security group
  cidr_ipv4   = "0.0.0.0/0"  # Allow all outbound traffic
  ip_protocol = -1  # All protocols
}

# Create an EC2 instance
resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id  # Use the AMI from the data source
  instance_type          = "t2.micro"  # Instance type
  subnet_id              = aws_subnet.web.id  # Associate with the subnet
  vpc_security_group_ids = [aws_security_group.web.id]  # Associate with the security group
  key_name               = "web-key"  # Key pair name
  user_data              = file("~/lab4/4640-w4-lab-start-w25/scripts/cloud-config.yaml")  # User data script

  tags = {
    Name    = "Web"  # Tag for the instance
    Project = local.lab4_marcus  # Project tag using local variable
  }
}

# Output the public IP and DNS of the EC2 instance
output "instance_ip_addr" {
  description = "The public IP and dns of the web ec2 instance."  # Description of the output
  value = {
    "public_ip" = aws_instance.web.public_ip  # Public IP of the instance
    "dns_name"  = aws_instance.web.public_dns  # Public DNS of the instance
  }
}
