resource "aws_security_group" "alb_sg" {
  name        = "app-test-alb-sg"
  description = "SG para ALB de app-test"
  vpc_id      = aws_vpc.app_test.id

  # HTTP desde la VPC completa
  ingress {
    from_port   = 80
    to_port     = 80
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
    Name        = "app-test-alb-sg"
  }
}

###########################
# Application Load Balancer
###########################
resource "aws_lb" "app_alb" {
  name               = "app-test-alb"
  load_balancer_type = "application"
  internal           = false                      # true = interno, false = internet-facing
  security_groups    = [aws_security_group.alb_sg.id]

  # ALB requiere al menos 2 subnets (2 AZ)
  subnets = [
    aws_subnet.public_az1.id,
    aws_subnet.public_az2.id,
  ]

  tags = {
    Name        = "app-test-alb"
  }
}

###########################
# Target Group
###########################
resource "aws_lb_target_group" "app_tg" {
  name     = "app-test-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.app_test.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
  }

  tags = {
    Name        = "app-test-tg"
  }
}


# Listener HTTP en el ALB

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "app_tg_attachment" {
  for_each = aws_instance.app_server

  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = each.value.id
  port             = 80
}
