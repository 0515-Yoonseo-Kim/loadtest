resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  tags = {
    Environment = var.environment
  }
}

# 프론트엔드 대상 그룹
resource "aws_lb_target_group" "frontend_tg" {
  name     = "${var.environment}-frontend-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# 백엔드 대상 그룹
resource "aws_lb_target_group" "backend_tg" {
  name     = "${var.environment}-backend-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"  # 백엔드 헬스 체크 경로
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# 리스너 규칙
# ALB 리스너 (포트 80) - 호스트 기반 라우팅 설정
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # default -> 프론트엔드
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

# 백엔드 규칙
resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 100 

  # api.qnq0615.com로 들어오는 요청 라우팅
  condition {
    host_header {
      values = ["api.qnq0615.com"]
    }
  }

  # 백엔드 대상 그룹
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

# 프론트엔드 EC2 인스턴스 연결 (포트 3000)
resource "aws_lb_target_group_attachment" "frontend_ec2_attach" {
  target_group_arn = aws_lb_target_group.frontend_tg.arn
  target_id        = aws_instance.app.id
  port             = 3000
}

# 백엔드 EC2 인스턴스 연결 (포트 5000)
resource "aws_lb_target_group_attachment" "backend_ec2_attach" {
  target_group_arn = aws_lb_target_group.backend_tg.arn
  target_id        = aws_instance.app.id
  port             = 5000
}
