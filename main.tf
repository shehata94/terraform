#Configure provider with access credentials 
provider "aws" {
    shared_config_files      = ["C:/Users/Kimo Hero/.aws/config"]
    shared_credentials_files = ["C:/Users/Kimo Hero/.aws/credentials"]
}

# Variables
variable "cidr_block_vpc" {}
variable "cidr_block_subnet" {}
variable "cidr_block_rt" {}
variable "my_ip" {}
variable "avail_zone" {}
variable "app_prefix" {}
variable "instance_type" {}
variable "key_file_path" {}

# create virtual private cloud 
resource "aws_vpc" "app-vpc" {
  cidr_block = var.cidr_block_vpc

  tags = {
    Name = "${var.app_prefix}-vpc"
  }
}

#create subnet in the vpc 
resource "aws_subnet" "app-subnet"{
  vpc_id = aws_vpc.app-vpc.id
  cidr_block = var.cidr_block_subnet
  availability_zone = var.avail_zone
    tags = {
    Name = "${var.app_prefix}-subnet"
  }
}

#create internet gateway 
resource "aws_internet_gateway" "app-igw" {
  vpc_id = aws_vpc.app-vpc.id

  tags = {
    Name = "${var.app_prefix}-igw"
  }
}

#create routing table 
resource "aws_route_table" "app-rt" {
  vpc_id = aws_vpc.app-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app-igw.id
  }

  tags = {
    Name = "${var.app_prefix}-rt"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.app-subnet.id
  route_table_id = aws_route_table.app-rt.id
}

# create security group 
resource "aws_security_group" "app-sg" {
  vpc_id      = aws_vpc.app-vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.my_ip]
  }

    ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_prefix}-sg"
  }
}

#create ec2 instance 
resource "aws_instance" "app-server"{
  ami = data.aws_ami.app-ami.id
  instance_type = var.instance_type
  availability_zone = var.avail_zone
  associate_public_ip_address = true

  key_name = aws_key_pair.key.key_name

  vpc_security_group_ids = [aws_security_group.app-sg.id]
  subnet_id = aws_subnet.app-subnet.id


  tags = {
    Name = "${var.app_prefix}-server"
  }
}

#get ami data
data "aws_ami" "app-ami" {
  most_recent      = true
  owners           = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

output "aws_ami_id" {
  value   = data.aws_ami.app-ami.id
}




#create key pair to ssh into sever
resource "aws_key_pair" "key" {
  key_name   = "server-key"
  public_key = file(var.key_file_path)
}