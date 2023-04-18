
## AWS ##
provider "aws" {
  access_key = "access"
  secret_key = "secret"
  region     = "eu-west-3"
}

## RECURSOS ##

# RED #
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

}

resource "aws_subnet" "subnet1" {
  cidr_block              = "10.0.0.0/24"
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true
}


resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta-subnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rtb.id
}

# GRUPO DE SEGURIDAD #
resource "aws_security_group" "ter-ansible" {
  name   = "ter_ansible"
  vpc_id = aws_vpc.vpc.id

  # SSH access
  ingress {
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
}

resource "aws_key_pair" "ter-key" {
  key_name   = "ter-key"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "local_file" "ter-key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "ter-key"
}

# INSTANCIA #
resource "aws_instance" "ansible" {
  ami                    = "ami-05bfef86a955a699e"
  instance_type          = "t2.micro"
  key_name               = "ter-key"
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.ter-ansible.id]

  user_data = <<EOF
#! /bin/bash
sudo apt update
sudo apt-get install python3 python3-pip -y
sudo pip3 install ansible
ansible --version
EOF

}

