#!/bin/bash

source $(dirname "$0")/env.sh

APP_NAME="buha-backend"
IMAGE_URI="${IMAGE_URI}" # GitHub Actions에서 전달됨
CODEDEPLOY_BUCKET="${CODEDEPLOY_BUCKET}" # GitHub Actions에서 전달됨
ECR_BACKEND_RESITRY="${ECR_BACKEND_RESITRY}" # GitHub Actions에서 전달됨

# S3에서 .env.production 다운로드
aws s3 cp s3://$CODEDEPLOY_BUCKET/env/.env.production /home/ec2-user/.env.production

# 🔐 ECR 로그인
aws ecr get-login-password --region ap-northeast-2 \
  | docker login --username AWS --password-stdin $ECR_BACKEND_RESITRY

docker pull $IMAGE_URI

# 기존 컨테이너 정리
docker stop $APP_NAME 2>/dev/null || true
docker rm $APP_NAME 2>/dev/null || true

# 컨테이너 실행
docker run -d \
  --name $APP_NAME \
  -p 5000:5000 \
  --env-file /home/ec2-user/.env.production \
  -v /home/ec2-user/global-bundle.pem:/app/global-bundle.pem \
  $IMAGE_URI