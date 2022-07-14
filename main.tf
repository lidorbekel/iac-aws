terraform {

  required_version = ">= 1.1.0"

  cloud {
    organization = "lidorbekel"

    workspaces {
      name = "lidor-iac-terraform"
    }
  }
}
provider "aws" {
  region = "eu-west-1"
}

variable "docker_compose" {
  type = string
  default =  <<EOF
version: "3.1"
services:
  hello:
    image: public.ecr.aws/t6p6b9i9/lidor-web-project:latest
    restart: always
    ports:
      - 8080:80
EOF
}

# Configure the VPC that we will use.
resource "aws_vpc" "prod" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "prod" {
  vpc_id = aws_vpc.prod.id
}

resource "aws_route" "prod__to_internet" {
  route_table_id = aws_vpc.prod.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.prod.id
}

resource "aws_subnet" "prod" {
  vpc_id = aws_vpc.prod.id
  availability_zone = "eu-west-1a"
  cidr_block = "10.0.0.0/18"
  map_public_ip_on_launch = true
  depends_on = [aws_internet_gateway.prod]
}

# Allow port 80 so we can connect to the container.
resource "aws_security_group" "allow_http" {
  name = "allow_http"
  vpc_id = aws_vpc.prod.id
  description = "security group"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
 
module "run_docker" {
  source =  "./modules/one_docker_instance_on_ec2"
  name = "lidor-web-demo"
  key_name = "ssh"
  instance_type = "t3.nano"
  docker_compose_str = var.docker_compose
  subnet_id = aws_subnet.prod.id
  availability_zone = aws_subnet.prod.availability_zone
  vpc_security_group_ids = [aws_security_group.allow_http.id]
  associate_public_ip_address = true
  persistent_volume_size_gb = 1
  
}
