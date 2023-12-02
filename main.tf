terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  backend "s3" {
    bucket = "gcaproni-bucket"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }

  required_version = ">= 1.2.0"
}


data "aws_availability_zones" "available" {
  state = "available"
}

provider "aws" {
  region = "us-east-1" # Update this to your desired AWS region
}

# VPC 

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16" 

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "gcaproni-vpc"
  }
}

# INTERNET GATEWAY 

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "gcapronii-igw"
  }
}

# SUBNETS

#Public 1
resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24" 
  availability_zone       = "us-east-1a"  
  map_public_ip_on_launch = true

  tags = {
    Name = "pub-subnet"
  }
}

#Public 2
resource "aws_subnet" "my_subnet2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

#Private 1
resource "aws_subnet" "my_private_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet"
  }
}

#Private 2
resource "aws_subnet" "my_private_subnet2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.102.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "private-subnet2"
  }
}


# PUBLIC ROUTE TABLES 

resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # rota padrão para a internet
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}


resource "aws_route_table_association" "my_association" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

resource "aws_route_table_association" "my_association2" {
  subnet_id      = aws_subnet.my_subnet2.id
  route_table_id = aws_route_table.my_route_table.id
}

# Elastic IP 

resource "aws_eip" "nat_elastic_ip" {
  depends_on = [aws_internet_gateway.my_igw]
  vpc = true
  tags = {
    Name = "nat-elastic-ip"
  }
}

# NAT GATEWAY 

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_elastic_ip.id
  subnet_id     = aws_subnet.my_subnet.id # Specify the subnet ID of the public subnet
}

resource "aws_route_table" "my_private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block     = "0.0.0.0/0" # rota padrão para a internet
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "nat-route-table"
  }
}

resource "aws_route_table_association" "my_private_association" {
  subnet_id      = aws_subnet.my_private_subnet.id
  route_table_id = aws_route_table.my_private_route_table.id
}

resource "aws_route_table_association" "my_private_association2" {
  subnet_id      = aws_subnet.my_private_subnet2.id
  route_table_id = aws_route_table.my_private_route_table.id
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}



# SECURITY GROUP 

#RDS

resource "aws_security_group" "my_security_group_rds" {
  name        = "gcaproni-sg_rds"
  description = "Security Group Description"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
    
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  tags = {
    Name = "gcaproni_sg_rds"
  }
}

#ec2

resource "aws_security_group" "my_security_group_ec2" {
  name        = "gcaproni-sg_ec2"
  description = "Security Group Description for WEB"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  
  }
  
  egress{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "gcaproni_sg_ec2"
  }
}

#load balancer

resource "aws_security_group" "my_security_group_lb" {
  name        = "gcaproni-sg_lb"
  description = "Security Group Description"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  tags = {
    Name = "gcaproni_sg_lb"
  }
}

# LOAD BALANCER 

#Target group
resource "aws_lb_target_group" "my_lb_target_group" {

  health_check {
    interval            = 10
    path                = "/healthcheck"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name        = "gcapronilb-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.my_vpc.id
}


#Creating load balancer
resource "aws_lb" "my_lb" {
  name               = "gcaproni-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my_security_group_lb.id]
  subnets            = [aws_subnet.my_subnet.id, aws_subnet.my_subnet2.id]

  tags = {
    Name = "gcaproni-lb"
  }
}

#creating listener
resource "aws_lb_listener" "my_lb_listener" {
  load_balancer_arn = aws_lb.my_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.my_lb_target_group.arn
    type             = "forward"
  }
}


# RDS 

resource "aws_db_subnet_group" "gcaproni-db-subnet-group" {
  name        = "gcaproni-db-subnet-group"
  description = "DB subnet group"
  subnet_ids  = [aws_subnet.my_private_subnet.id, aws_subnet.my_private_subnet2.id]
}

resource "aws_db_instance" "my_db_instance" {
  allocated_storage       = 10
  storage_type            = "gp2"
  engine                  = "mysql"
  engine_version          = "5.7"
  instance_class          = "db.t2.micro"
  db_name                 = "caproni_db"
  username                = "dbadmin"
  password                = "secretpassword"
  db_subnet_group_name    = aws_db_subnet_group.gcaproni-db-subnet-group.name
  vpc_security_group_ids  = [aws_security_group.my_security_group_rds.id]
  skip_final_snapshot     = true
  backup_retention_period = 5
  backup_window           = "01:00-01:30"
  maintenance_window      = "Mon:03:00-Mon:05:00"
  multi_az                = true
  publicly_accessible = false
}

# AUTO SCALING GROUP ---------------------------------------------------------------------------------

resource "aws_launch_template" "my_launch_template" {
  name_prefix   = "gcaproni-launch-template"
  image_id      = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.micro"
  user_data = base64encode(<<-EOF
    #!/bin/bash
    sudo touch app.log 
    export DEBIAN_FRONTEND=noninteractive

    sudo apt -y remove needrestart
    echo "fez o needrestart" >> app.log
    sudo apt-get update
    echo "fez o update" >> app.log
    sudo apt-get install -y python3-pip python3-venv git
    echo "fez o install de tudo" >> app.log

    # Criação do ambiente virtual e ativação
    python3 -m venv /home/ubuntu/myappenv
    echo "criou o env" >> app.log
    source /home/ubuntu/myappenv/bin/activate
    echo "ativou o env" >> app.log

    # Clonagem do repositório da aplicação
    git clone https://github.com/ArthurCisotto/aplicacao_projeto_cloud.git /home/ubuntu/myapp
    echo "clonou o repo" >> app.log

    # Instalação das dependências da aplicação
    pip install -r /home/ubuntu/myapp/requirements.txt
    echo "instalou os requirements" >> app.log

    sudo apt-get install -y uvicorn
    echo "instalou o uvicorn" >> app.log
 
    # Configuração da variável de ambiente para o banco de dados
    export DATABASE_URL="mysql+pymysql://dbadmin:secretpassword@${aws_db_instance.my_db_instance.endpoint}/caproni_db"
    echo "exportou o url" >> app.log

    cd /home/ubuntu/myapp
    # Inicialização da aplicação
    uvicorn main:app --host 0.0.0.0 --port 80 
    echo "inicializou" >> app.log
  EOF
  )

  network_interfaces {
    security_groups             = [aws_security_group.my_security_group_ec2.id]
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.my_subnet.id
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "gcaproni-launch-template"
    }
  }
}

resource "aws_autoscaling_group" "my_autoscaling_group" {
  name             = "gcaproni-autoscaling-group"
  desired_capacity = 2
  max_size         = 5
  min_size         = 1

  force_delete = true
  vpc_zone_identifier = [aws_subnet.my_subnet.id]
  target_group_arns   = [aws_lb_target_group.my_lb_target_group.arn]

  health_check_grace_period = 250
  health_check_type         = "ELB"

  launch_template {
    id      = aws_launch_template.my_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "gcaproni-autoscaling-group"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 180
  autoscaling_group_name = aws_autoscaling_group.my_autoscaling_group.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 180
  autoscaling_group_name = aws_autoscaling_group.my_autoscaling_group.name
}

resource "aws_cloudwatch_metric_alarm" "alarm_up" {
  alarm_name          = "alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "50"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  ok_actions          = [aws_autoscaling_policy.scale_down.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.my_autoscaling_group.name
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm_down" {
  alarm_name          = "alarm_down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "15"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  ok_actions          = [aws_autoscaling_policy.scale_up.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.my_autoscaling_group.name
  }
}



