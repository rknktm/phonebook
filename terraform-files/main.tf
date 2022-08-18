
data "aws_vpc" "default" {
    default = true
}
##############################################################
data "aws_subnets" "default" {
    filter {
        name   = "vpc-id"
        values = [data.aws_vpc.default.id]
    }
}
#################################################################
data "aws_ami" "amazon-linux-2" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm*"]
  }
}
#################################################################
resource "aws_lb_target_group" "tf-TG" {
  target_type = "instance"
  name     = "tf-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 3
  }
  tags = {
    Name = "tf-TG"
  }
}
################################################################
resource "aws_lb" "tf-ALB" {
  name               = "tf-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-SG.id]
  subnets = data.aws_subnets.default.ids
  #subnets           = [for subnet in aws_subnet.public : subnet.id]
  tags = {
      Name = "tf-ALB"
    }
}
################################################################
resource "aws_lb_listener" "listener-80" {
  load_balancer_arn = aws_lb.tf-ALB.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tf-TG.arn
  }
}
##################################################################
resource "aws_launch_template" "tf-LT" {
  depends_on = [
    github_repository_file.dbendpoint
  ]
  name_prefix   = "myTF-LT"
  image_id      = data.aws_ami.amazon-linux-2.id
  instance_type = var.instance-type
  key_name = var.key
   vpc_security_group_ids = [aws_security_group.web-SG.id] #another option

  user_data = filebase64("${abspath(path.module)}/user-data.sh") 
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "tf-LT"
    }
  }
}
#######################################################################
resource "aws_autoscaling_group" "tf-ASG" {
  name                      = "tf-ASG"
  desired_capacity          = 2
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  vpc_zone_identifier = aws_lb.tf-ALB.subnets
  target_group_arns = [aws_lb_target_group.tf-TG.arn]
  launch_template {
    id      = aws_launch_template.tf-LT.id
    version = "$Latest"
  }
}
################################################################
resource "aws_db_instance" "tf-RDS" {
  allocated_storage       = 20
  max_allocated_storage   = 40
  storage_type            = "gp2"
  engine                  = "mysql"
  engine_version          = "8.0.19"
  instance_class          = "db.t2.micro"
  identifier              = "tf-phonebook-db"
  db_name                 = var.DatabaseName
  username                = var.UserName
  password                = var.Password
  vpc_security_group_ids  = [aws_security_group.rds-SG.id]
  allow_major_version_upgrade = false
  auto_minor_version_upgrade = true 
  skip_final_snapshot     = true
  #db_subnet_group_name    = aws_db_subnet_group.tf-SubnetGroup.name
  monitoring_interval = 0
  multi_az = false
  port = 3306
  publicly_accessible = false  
}
###################################################################
resource "github_repository_file" "dbendpoint" {
  repository          = "phonebook"
  branch              = "main"
  file                = "dbserver.endpoint"
  content             = aws_db_instance.tf-RDS.address
  overwrite_on_create = true
}
##################################################################




