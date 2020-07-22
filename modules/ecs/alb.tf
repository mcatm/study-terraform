
# STEP1: セキュリティグループの作成
# https://www.terraform.io/docs/providers/aws/r/security_group.html

resource "aws_security_group" "alb" {
  name        = "${var.prefix}-alb"
  description = "${var.prefix} alb"
  vpc_id      = aws_vpc.main.id

  # セキュリティグループ内のリソースからインターネットへのアクセスを許可する
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-alb"
  }
}



# STEP2: セキュリティルールの設定
# https://www.terraform.io/docs/providers/aws/r/security_group.html

resource "aws_security_group_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  # セキュリティグループ内のリソースへインターネットからのアクセスを許可する
  type = "ingress"

  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}



# STEP3: ALB（Application Load Balancer）
# https://www.terraform.io/docs/providers/aws/d/lb.html

resource "aws_lb" "main" {
  load_balancer_type = "application"
  name               = var.prefix

  security_groups = ["${aws_security_group.alb.id}"]
  subnets         = ["${aws_subnet.public_1a.id}", "${aws_subnet.public_1c.id}", "${aws_subnet.public_1d.id}"]
}



# STEP4: Listener
# https://www.terraform.io/docs/providers/aws/r/lb_listener.html

resource "aws_lb_listener" "main" {
  # HTTPでのアクセスを受け付ける
  port              = "80"
  protocol          = "HTTP"

  # ALBのarnを指定します。
  load_balancer_arn = aws_lb.main.arn

  # "ok" という固定レスポンスを設定する
  default_action {
    type             = "fixed-response"

    fixed_response {
        content_type = "text/plain"
        status_code  = "200"
        message_body = "ok"
    }
  }
}

