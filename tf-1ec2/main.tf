###########################
### Launch a web server ###
###########################

### Terraform Init
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

### Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}


##########################
### Default Variables  ###
##########################
variable "aws_region" {
  description = "AWS Region to spin up everything at"
  default = "eu-central-1"
}

variable "availability_zone" {
  description = "Main AZ where to spin up our EC2 instance"
  default = "eu-central-1a"
}

variable "subnet_prefix" {
  description = "CIDR block for subnet"
  default = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 Instance type"
  default = "t2.micro"
}

variable "instance_ami" {
  description = "AMI for EC2 instance"
  default = "ami-00a205cb8e06c3c4e"
}

variable "ssh_key_name" {
  description = "Your SSH key name"
  default = "dspv1"
}

###############
### Modules ###
###############
### 1. VPC
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "production"
  }
}

### 2. IGW
resource "aws_internet_gateway" "prod-igw" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    Name = "prod-igw"
  }
}

### 3. Route Table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0" # All traff
    gateway_id = aws_internet_gateway.prod-igw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.prod-igw.id
  }

  tags = {
    Name = "prod-route-table"
  }
}

### 4. Subnet
resource "aws_subnet" "prod-subnet-1" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = var.subnet_prefix
  availability_zone = var.availability_zone

  tags = {
    Name = "prod-subnet"
  }
}

### 5. Associate subnet the route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.prod-subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

### 6. Secutury Group to allow ports 22, 80, 443
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow WEB traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-web"
  }
}

### 7. Network interface with an IP in the subnet that was created on step 4
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.prod-subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

#  attachment {
#    instance     = aws_instance.test.id
#    device_index = 1
#  }
}

### 8. Assign an EIP to the network interface create on step 7
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.prod-igw]
}

### 9. Install web server on Amazon2 EC2 instance
resource "aws_instance" "web-server-instance" {
  ami               = var.instance_ami
  instance_type     = var.instance_type
  availability_zone = var.availability_zone
  key_name          = var.ssh_key_name
  
  root_block_device {
    volume_size       = "30"
  }
  
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id

  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              # --- Install Docker
              amazon-linux-extras install docker
              service docker start
              # --- Fix the rights
              sudo usermod -a -G docker ec2-user
              docker info
              # --- Make Docker auto-start
              sudo chkconfig docker on
              # ---  Git
              yum install -y git
              # --- Docker compose
              sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
              sudo chmod +x /usr/local/bin/docker-compose
              docker-compose version
              EOF

  tags = {
    Name = "prod-web-server"
  }
}


#############################
### Make some output data ###
#############################

output "server_public_ip" {
  value = aws_eip.one.public_ip
}

output "server_public_dns" {
  value = aws_eip.one.public_dns
}