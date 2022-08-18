# ALB Security Group
resource "aws_security_group" "alb-SG" {
  name        = "ALB-SG"
  description = "ALB Security Group allows traffic HTTP" 
  vpc_id      = data.aws_vpc.default.id
  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
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
    Name = "ALB-SecurityGroup"
  }
  }
####################################################################
# Ec2 SG
resource "aws_security_group" "web-SG" {
  name        = "Server-SG"
  description = "Allows traffic coming from ALB_Sec_Group Security Group  for HTTP port,ssh port is allowed from anywherewe"
  ingress {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
      description      = "HTTP"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      security_groups  = [aws_security_group.alb-SG.id]
  }
  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "web-SecurityGroup"
  }
}
###################################################################
#RDS-SG
resource "aws_security_group" "rds-SG" {
  name        =  "RDS-SG"
  description = "RDS Security Groups only allows traffic coming from web-SG for MYSQL/Aurora port."
  ingress {
    description      = "MYSQL/Aurora port"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups = [aws_security_group.web-SG.id]
  }
  tags = {
    Name = "rds-SecurityGroup"
  }
}