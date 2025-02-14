resource "aws_security_group" "ec2_sg" {
  name        = "${var.environment}-ec2-sg"
  description = "Security Group for EC2"
  vpc_id      = var.vpc_id

  # ALB에서 3000번 포트 접근 허용
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # ALB에서만 접근 허용
  }

  # ALB에서 5000번 포트 접근 허용
  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # ALB에서만 접근 허용
  }

  # SSH 접속
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 외부로 나가는 모든 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # 모든 프로토콜 허용
    cidr_blocks = ["0.0.0.0/0"]
  }
}
