

#++++++++++++++++++++++++++++++++++++++ Ongoing Handson File ++++++++++++++++++++++++++++++++++++++#


##################################################################################################################
# 1. Create AWS Provider
##################################################################################################################

provider "aws" {
    region = "us-east-2"
    access_key = "########################"
    secret_key = "########################"
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
  vpc_security_group_ids = [aws_security_group.WS-SG.id] # this will take SecurityGrpId once it created as writtent in SG creation.

  # Keyname and security group are obtained from the reference of their instances created above!
  # Here I am providing the name of the key which is already uploaded on the AWS console.
  key_name = "KunjanKey"

  # Security groups to use!
  # vpc_security_group_ids = [aws_security_group.WS-SG.id]

  tags = {
   Name = "kunjanweb_From_Terraform"
  }


}

############################################################################################################
# Application Load Balancer
############################################################################################################

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = "alb-terraform-kunjan"

  load_balancer_type = "application"

  vpc_id             = "vpc-036d31bd5fc70a5ef" # Entered alredy created vpc 'VPC-SquareOps-Ohio'
  subnets            = ["subnet-09a50a0db3bdf9d87", "subnet-0c7ecd015c8189600"] # Public Subnets IDS for VPC
  security_groups    = ["sg-0ddeb3fa52ec1ac31"] # Added Created SG Id with allowed ports "22,80,443"

  target_groups = [
    {
      name_prefix      = "Tkunj" # treat as prefix of load-balancer-name
      backend_protocol = "HTTP" # Backend Protocol
      backend_port     = 80 # Backend port
      target_type      = "instance" # This Load-balancer will target instance
      targets = {
        my_target = {
          target_id =  aws_instance.k-webserver.id # Load Balancer will forward request to this EC2 machine
          port = 80 # Load Balancer will forward request to this port
        }
      }
    }
  ]

  https_listeners = [
    {
      port               = 443 # adding listner port
      protocol           = "HTTPS" # adding listner protocol
      certificate_arn    = "arn:aws:acm:us-east-2:421320058418:certificate/df35a587-5429-4738-9477-5032add3142d" # adding approved ACM certificate ARN num.
      target_group_index = 0 # It's not clear
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80 # adding listner port
      protocol           = "HTTP" # adding listner protocol
      target_group_index = 0 # It's not clear
    }
  ]

  tags = {
    Name = "terraform-tg-kunjan" # Name of target Group
  }
}
