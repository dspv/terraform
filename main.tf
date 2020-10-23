terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# 1. VPC
# 2. IGW
# 3. Custom Route Table
# 4. Subnet
# 5. Associate subnet the route table
# 6. Secutury Group to allow ports 22, 80, 443
# 7. Network interface with an IP in the subnet that was created on step 4
# 8. Assign an EIP to the network interface create on step 7
# 9. Install Ubuntu server and install/ebable Apache 2
# test

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

#resource "aws_instance" "terra-nova" {
#  ami               = "ami-0947d2ba12ee1ff75"
#  instance_type     = "t2.micro"
#  availability_zone = "us-east-1a"
#  key_name          = "dspv1-kp"
#  volume_size       = "30"
#
#  tags = {
#    Name = "Terra Nova"
#  }
#}

### VPC ###
############
resource "aws_vpc" "terra-main-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Terra Main VPC"
  }
}

resource "aws_vpc" "terra-second-vpc" {
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "Terra Second VPC"
  }
}

### Subnets ###
###############
resource "aws_subnet" "terra-subnet-1" {
  vpc_id     = aws_vpc.terra-main-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "production"
  }
}

resource "aws_subnet" "terra-subnet-2" {
  vpc_id     = aws_vpc.terra-second-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "development"
  }
}


# resource "<provider>_<resource-type>" "name" {
#   Config option 
#   key = "value"
#   key2 = "another value"
# }