resource "aws_instance" "app" {
  ami                    = var.ami_id # git, docker, docker-compose 설치된 AMI
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id] # EC2에 올바른 보안 그룹 적용
  key_name               = var.key_name

  root_block_device {
    volume_size           = 20  # 기본 볼륨 크기 
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "${var.environment}-app"
  }
}

# 탄력적 IP 할당 (기존 EIP 사용)
resource "aws_eip_association" "app_eip_assoc" {
  instance_id   = aws_instance.app.id
  allocation_id = "${var.eip}" # 기존 EIP의 Allocation ID 입력
}