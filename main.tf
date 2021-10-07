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
  access_key = ""
  secret_key = ""
}

resource "aws_vpc" "main" {
  cidr_block       = "172.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "RedHatTest"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.0.32.0/24"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "RedHat_Subnet1"
  }
}
resource "aws_subnet" "main2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.0.64.0/24"
  availability_zone = "eu-central-1b"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "RedHat_Subnet2"
  }
}
resource "aws_subnet" "main3" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.0.96.0/24"
  availability_zone = "eu-central-1c"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "RedHat_Subnet3"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "RedHat_InternetGateway"
  }
}

resource "aws_vpc_dhcp_options" "dhcp_option" {
  domain_name          = "eu-central-1.compute.internal"
  domain_name_servers  = ["AmazonProvidedDNS"]

  tags = {
    Name = "Redhat_DHCP"
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}


resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "RedHat_Routetable"
  }
}

resource "aws_route_table_association" "route_table_associate_1" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.route_table.id
}
resource "aws_route_table_association" "route_table_associate_2" {
  subnet_id      = aws_subnet.main2.id
  route_table_id = aws_route_table.route_table.id
}
resource "aws_route_table_association" "route_table_associate_3" {
  subnet_id      = aws_subnet.main3.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_security_group" "sg_master" {
  name = "redhat_sg_master"
  vpc_id = aws_vpc.main.id
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
  tags = {
    Name = "RedHatMasterSG"
  }
}

resource "aws_security_group" "sg_worker" {
  name = "redhat_sg_worker"
  vpc_id = aws_vpc.main.id
  ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port = 8
      to_port = 0
      protocol = "icmp"
      cidr_blocks = ["0.0.0.0/0"]
  }
 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "RedHatWorkerSG"
  }
}

variable "amis" {
    default = {
        "eu-central-1" = "ami-009b16df9fcaac611"
    }
}
variable "region" {
        default = "eu-central-1"
}

resource "aws_key_pair" "key_pair" {
  key_name   = ""
  public_key = ""
}

resource "aws_instance" "redhat_ec2_master" {
  ami           = lookup(var.amis, var.region) 
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg_master.id]
  subnet_id = aws_subnet.main.id
  key_name = aws_key_pair.key_pair.key_name
  root_block_device{
   delete_on_termination = true
   volume_size = 10
   volume_type = "gp2"
  }
  tags = {
    Name = "RedHatMaster"
  }
}


resource "aws_instance" "redhat_ec2_worker" {
  count = 3
  ami           = lookup(var.amis, var.region) 
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg_worker.id]
  subnet_id = aws_subnet.main.id
  key_name = aws_key_pair.key_pair.key_name
  root_block_device{
   delete_on_termination = true
   volume_size = 10
   volume_type = "gp2"
  }
  tags = {
    Name = "RedHatWorker-${count.index+1}"
  }
}