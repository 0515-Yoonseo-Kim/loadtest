#!/bin/bash

APP_NAME="buha-backend"
IMAGE_URI="${IMAGE_URI}" # GitHub Actions에서 전달됨
SECRET_NAME="${SSM_SECRET}" # GitHub Actions에서 전달됨

# 시크릿에서 username과 password 꺼내기
USERNAME=$(aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" \
  --query 'SecretString' --output text | jq -r '.username')

PASSWORD_RAW=$(aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" \
  --query 'SecretString' --output text | jq -r '.password')

PASSWORD=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$PASSWORD_RAW'''))")

# DocumentDB 접속 URI 조립
MONGO_URI="mongodb://${USERNAME}:${PASSWORD}@docdb-2025-03-28-14-07-29.cluster-cdc4iccm43ba.ap-northeast-2.docdb.amazonaws.com:27017/?tls=true&tlsCAFile=global-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"

# 🔐 ECR 로그인
aws ecr get-login-password --region ap-northeast-2 \
  | docker login --username AWS --password-stdin 851725239852.dkr.ecr.ap-northeast-2.amazonaws.com

# 기존 컨테이너 정리
docker stop $APP_NAME 2>/dev/null || true
docker rm $APP_NAME 2>/dev/null || true

# 컨테이너 실행
docker run -d \
  --name $APP_NAME \
  -e MONGO_URI="$MONGO_URI" \
  -v /home/ec2-user/global-bundle.pem:/app/global-bundle.pem \
  $IMAGE_URI