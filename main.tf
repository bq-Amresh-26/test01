provider "aws" {
  region  = "us-east-1"
  
}
# provider "aws" {
#     alias = "us-east-1"
#     region = "us-east-1"
  
# }

# resource "aws_instance" "app_server" {
#   ami           = "ami-08d70e59c07c61a3a"
#   instance_type = "t2.micro"
#   tags = {
#     Name = "Amresh_Server_01"
#   }
# }

#1 creating vpc 
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = " Vpc_Terraform"
  }
}

# 2 Cretraing internet gateways

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-gateway"
  }
}

# 3 Creating custom route table
# ===================================

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/8"
    gateway_id = aws_internet_gateway.gw.id
  }

#   route {
#     ipv6_cidr_block        = "::/0"
#     egress_only_gateway_id = aws_internet_gateway.gw.id
#   }

  tags = {
    Name = "customRouteTable"
  }
}

# 4 creating subnet
resource "aws_subnet" "subnet-1" {
    vpc_id = aws_vpc.main.id
    cidr_block ="10.0.1.0/24"
    availability_zone = "us-east-1a"
    tags = {
      Name = "public_subnet"
    }

  
}

#5 route table association

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.example.id
}


# creating security group

resource "aws_security_group" "allow_tls" {
  name        = "allow_all_traffic"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "HTTPs from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }
   ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }
   ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web_to_acces_vpc"
  }
}

# creating network interface
 resource "aws_network_interface" "test" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
#   security_groups = [aws_security_group.web.id]
security_groups = [aws_security_group.allow_tls.id]

}

# creating single Elastic IP
 resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.test.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [
    aws_internet_gateway.gw
  ]
}

# creaating server on this this vpc

resource "aws_instance" "web-server-Instances" {
    ami = "ami-00874d747dde814fa"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "main-key"
    network_interface {
      device_index=0
      network_interface_id=aws_network_interface.test.id
    }

  

       tags = {
         Name = "Ec2_from_custom_vpc"
       }
            

      
  
}