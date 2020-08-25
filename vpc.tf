provider "aws" {
    region = "ap-southeast-1"
}

# Must have existing key pair


variable "subnet_cidr_block" {
  description = "cidr block for the subnet"
}

# vpc
resource "aws_vpc" "dev-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Dev_vpc"
  }
}

# internet gateway
resource "aws_internet_gateway" "dev-igw" {
  vpc_id = aws_vpc.dev-vpc.id
}

# route table
resource "aws_route_table" "dev-route-table" {
  vpc_id = aws_vpc.dev-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev-igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.dev-igw.id
  }

  tags = {
    Name = "Dev_route_table"
  }
}

# subnet
resource "aws_subnet" "dev-subnet-1" {
  vpc_id     = aws_vpc.dev-vpc.id
  cidr_block = var.subnet_cidr_block[0]
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "Dev_subnet1"
  }
}

resource "aws_subnet" "dev-subnet-2" {
  vpc_id     = aws_vpc.dev-vpc.id
  cidr_block = var.subnet_cidr_block[1]
  availability_zone = "ap-southeast-1b"

  tags = {
    Name = "Dev_subnet2"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.dev-subnet-1.id
  route_table_id = aws_route_table.dev-route-table.id
}

# security group
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.dev-vpc.id

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
    Name = "allow_tls"
  }
}

# network interface
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.dev-subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_tls.id]
}

# assign EIP
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.dev-igw]
}

output "server_public_ip" {
    value = aws_eip.one.public_ip
}

# create ec2 ubuntu instance

resource "aws_instance" "web" {
  ami           = "ami-0007cf37783ff7e10"
  instance_type = "t2.micro"
  availability_zone = "ap-southeast-1a"
  key_name = "terraform-key-pair"
  
  network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo Hello World > /var/www/html/index.html'
                EOF

  tags = {
    Name = "web_server"
  }
}
