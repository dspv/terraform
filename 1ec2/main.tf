### Terraform Init
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

### Set AMI: Ubuntu, latest @ Secelted Region
data "aws_ami" "ubuntu" {
  most_recent   = true
  owners        = ["099720109477"] # Canonical  

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "ec2-nano" {
  ami               = data.aws_ami.ubuntu.id
  instance_type     = "t2.nano"
}

resource "aws_instance" "ec2-micro" {
  ami               = data.aws_ami.ubuntu.id
  instance_type     = "t2.micro"
}