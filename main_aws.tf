terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    # The name of your Terraform Cloud organization.
    
    organization = "test-trainee-tf"
    
    # The name of the Terraform Cloud workspace to store Terraform state files in.
    workspaces {
      name = "tarea-infra"
    }
  }
}


provider "aws" {
  region = "us-east-2"
}

resource "aws_vpc" "mi-vpc"{
  cidr_block = "10.0.0.0/21"
  
}

resource "aws_subnet" "subnet01" {
depends_on = [ aws_vpc.mi-vpc ]

  cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.mi-vpc.id
}

resource "aws_route_table" "mi-routetable-sofi" {

  depends_on = [ aws_vpc.mi-vpc ]

  vpc_id = aws_vpc.mi-vpc.id

  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-sofi.id
  }

  tags = {
    Name = "rtable-attached-w-igw"
  }
}

resource "aws_route_table_association" "asociacion-subnet-public1" {
  depends_on = [ aws_route_table.mi-routetable-sofi ]
  subnet_id = aws_subnet.subnet01.id
  route_table_id = aws_route_table.mi-routetable-sofi.id
}

resource "aws_internet_gateway" "igw-sofi" {
  depends_on = [ aws_vpc.mi-vpc ]

  vpc_id = aws_vpc.mi-vpc.id

  tags = {
  Name = "igw-sofi"
  }
}

resource "aws_security_group" "demo_sg"{
  vpc_id = aws_vpc.mi-vpc.id
  depends_on = [ aws_internet_gateway.igw-sofi]
  tags ={
    Name="demo_sg"
  }

    ingress{
    from_port=22
    to_port=22
    protocol="tcp"
    cidr_blocks=["0.0.0.0/0"]
  }

  ingress{
    from_port=22
    to_port=22
    protocol="tcp"
    cidr_blocks=["186.128.49.179/32"]
  }


  egress{
    from_port=0
    to_port=0
    protocol="-1"
    cidr_blocks=["0.0.0.0/0"]
  }
}


resource "aws_instance" "sof-demo" {
  depends_on = [ aws_security_group.demo_sg ]

  ami                    = "ami-050cd642fd83388e4"
  instance_type          = "t2.micro"
  subnet_id = aws_subnet.subnet01.id
  associate_public_ip_address = true
  key_name = "ParDeClaves"

  security_groups = [aws_security_group.demo_sg.id]


  tags = {
    Name="mi-ec2-de-pruebita"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hola Mundo desde chofi</h1>" > /var/www/html/index.html
              nohup busybox httpd -f -p 8080 &
              EOF
}

