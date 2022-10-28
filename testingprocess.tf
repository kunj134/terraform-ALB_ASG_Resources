

########################################## Ongoing Handson File ################################################

##################################################################################################################
# 1. Create AWS Provider
##################################################################################################################

provider "aws" {
    region = "us-east-2"
    access_key = "#######################"
    secret_key = "#######################"
}

##################################################################################################################
# 2. Create public facing EC2 within existing VPC
##################################################################################################################

resource "aws_instance" "k-webserver" {

#  depends_on = [
#    aws_vpc.VPC-SquareOps-Ohio,
#    aws_subnet.VPC-SquareOps-Public-Subnet1,
#    aws_subnet.VPC-SquareOps-Public-Subnet2,
#  ]

  # AMI ID [I have used my custom AMI which has some softwares pre installed]
  ami = "ami-0d5bf08bc8017c83b"
  instance_type = "t3a.small"
# vpc_id = "vpc-036d31bd5fc70a5ef"
  subnet_id = "subnet-09a50a0db3bdf9d87"


  # Keyname and security group are obtained from the reference of their instances created above!
  # Here I am providing the name of the key which is already uploaded on the AWS console.
  key_name = "KunjanKey"

  # Security groups to use!
  # vpc_security_group_ids = [aws_security_group.WS-SG.id]

  tags = {
   Name = "Webserver_From_Terraform"
  }


}

##################################################################################################################
# 3. Creating SG for Wordpress Instance
##################################################################################################################

# Creating a Security Group for WordPress
resource "aws_security_group" "WS-SG" {

#  depends_on = [
#    aws_vpc.custom,
#    aws_subnet.subnet1,
#    aws_subnet.subnet2
#  ]

  description = "HTTP, PING, SSH"

  # Name of the security Group!
  name = "webserver-sg"

  # VPC ID in which Security group has to be created!
  vpc_id = "vpc-036d31bd5fc70a5ef"

  # Created an inbound rule for webserver access!
  ingress {
    description = "HTTP for webserver"
    from_port   = 80
    to_port     = 80

    # Here adding tcp instead of http, because http in part of tcp only!
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Created an inbound rule for ping
  ingress {
    description = "Ping"
    from_port   = 0
    to_port     = 0
    protocol    = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Created an inbound rule for SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22

    # Here adding tcp instead of ssh, because ssh in part of tcp only!
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outward Network Traffic for the WordPress
  egress {
    description = "output from webserver"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
