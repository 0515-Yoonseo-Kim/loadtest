#!/bin/bash

# 실행할 서비스 목록
services=("MongoDB" "Redis" "Backend" "Frontend")

# 백엔드 및 프론트엔드 경로 설정
BACKEND_DIR="./loadtest-backend"
FRONTEND_DIR="./loadtest-frontend"

# 로그 파일 경로
LOG_DIR="./logs"

# 데이터 디렉토리 경로 (Docker Compose에서 사용)
DATA_DIR="$HOME/data/db"

# PM2 프로세스 이름 설정
PM2_BACKEND_NAME="loadtest-backend-server"
PM2_FRONTEND_NAME="loadtest-frontend-server"

# Docker Compose 설정
DOCKER_COMPOSE_DIR="./"
# 명령어 인자 확인
if [ $# -eq 0 ] || [ $# -gt 2 ]; then
  echo "사용법: ./run.sh {start|stop|restart|status} [mode]"
  echo "mode 옵션: dev (기본값) | prod"
  echo "예시:"
  echo "  ./run.sh start         # 개발 모드로 시작"
  echo "  ./run.sh start prod    # 프로덕션 모드로 시작"
  exit 1
fi

# 실행 모드 설정 (두 번째 인자가 없으면 dev로 설정)
MODE=${2:-dev}

# 시스템 상태 체크 함수
check_system_status() {
  echo "시스템 상태를 확인합니다..."
  
  # MongoDB 포트 (27017) 확인
  if lsof -i:27017 >/dev/null 2>&1; then
    echo "경고: MongoDB 포트(27017)가 이미 사용 중입니다."
  fi
  
  # Redis 포트 (6379) 확인
  if lsof -i:6379 >/dev/null 2>&1; then
    echo "경고: Redis 포트(6379)가 이미 사용 중입니다."
  fi
  
  # 디스크 공간 확인
  DISK_SPACE=$(df -h "$DATA_DIR" | awk 'NR==2 {print $4}')
  echo "사용 가능한 디스크 공간: $DISK_SPACE"
}

# 함수 정의
start_services() {
  echo "서비스를 시작합니다... (모드: $MODE)"
  
  check_system_status

  # 데이터 디렉토리 확인 및 생성
  if [ ! -d "$DATA_DIR" ]; then
    echo "데이터 디렉토리가 존재하지 않습니다. 생성합니다: $DATA_DIR"
    mkdir -p "$DATA_DIR"
    # 권한 설정
    chmod 755 "$DATA_DIR"
  else
    echo "데이터 디렉토리가 이미 존재합니다: $DATA_DIR"
  fi

  # 로그 디렉토리 생성
  mkdir -p "$LOG_DIR"

  # Docker Compose를 통한 MongoDB 및 Redis 시작
  echo "MongoDB 및 Redis를 Docker Compose로 시작합니다..."
  if [ -f "$DOCKER_COMPOSE_DIR/docker-compose.yaml" ]; then
    docker-compose -f "$DOCKER_COMPOSE_DIR/docker-compose.yaml" up -d
    if [ $? -eq 0 ]; then
      echo "MongoDB 및 Redis가 Docker Compose를 통해 시작되었습니다."
    else
      echo "MongoDB 및 Redis 시작에 실패했습니다."
      exit 1
    fi
  else
    echo "docker-compose.yaml 파일을 찾을 수 없습니다: $DOCKER_COMPOSE_DIR/docker-compose.yaml"
    exit 1
  fi

  # 백엔드 시작
  if ! pm2 list | grep -q "$PM2_BACKEND_NAME"; then
    echo "백엔드 서버를 시작합니다... (모드: $MODE)"
    cd "$BACKEND_DIR"
    NODE_ENV=$MODE pm2 start server.js --name "$PM2_BACKEND_NAME" \
      --log "$LOG_DIR/backend.log" \
      --error "$LOG_DIR/backend-error.log"
    cd ..
  else
    echo "백엔드 서버가 이미 실행 중입니다."
  fi

  # 프론트엔드 시작
  if ! pm2 list | grep -q "$PM2_FRONTEND_NAME"; then
    echo "프론트엔드 서버를 시작합니다... (모드: $MODE)"
    cd "$FRONTEND_DIR"
    
    if [ "$MODE" = "prod" ]; then
      echo "프론트엔드 프로덕션 빌드를 시작합니다..."
      npm run build
      pm2 start npm --name "$PM2_FRONTEND_NAME" \
        --log "$LOG_DIR/frontend.log" \
        --error "$LOG_DIR/frontend-error.log" \
        -- start
    else
      pm2 start npm --name "$PM2_FRONTEND_NAME" \
        --log "$LOG_DIR/frontend.log" \
        --error "$LOG_DIR/frontend-error.log" \
        -- run dev -- -p 3000
    fi
    
    cd ..
  else
    echo "프론트엔드 서버가 이미 실행 중입니다."
  fi

  echo "모든 서비스가 시작되었습니다."
  pm2 list
}

stop_services() {
  echo "서비스를 중지합니다..."

  # Stop PM2 managed services
  for service in "$PM2_FRONTEND_NAME" "$PM2_BACKEND_NAME"; do
    if pm2 list | grep -q "$service"; then
      echo "$service 중지 중..."
      pm2 stop "$service"
      pm2 delete "$service"
    fi
  done

  # Stop Docker Compose managed services
  echo "MongoDB 및 Redis를 Docker Compose로 중지합니다..."
  if [ -f "$DOCKER_COMPOSE_DIR/docker-compose.yaml" ]; then
    docker-compose -f "$DOCKER_COMPOSE_DIR/docker-compose.yaml" down
    if [ $? -eq 0 ]; then
      echo "MongoDB 및 Redis가 Docker Compose를 통해 중지되었습니다."
    else
      echo "MongoDB 및 Redis 중지에 실패했습니다."
      exit 1
    fi
  else
    echo "docker-compose.yaml 파일을 찾을 수 없습니다: $DOCKER_COMPOSE_DIR/docker-compose.yaml"
    exit 1
  fi

  echo "모든 서비스가 중지되었습니다."
  pm2 list
}

restart_services() {
  echo "서비스를 재시작합니다... (모드: $MODE)"
  
  # Restart Docker Compose managed services
  echo "MongoDB 및 Redis를 Docker Compose로 재시작합니다..."
  if [ -f "$DOCKER_COMPOSE_DIR/docker-compose.yaml" ]; then
    docker-compose -f "$DOCKER_COMPOSE_DIR/docker-compose.yaml" restart
    if [ $? -eq 0 ]; then
      echo "MongoDB 및 Redis가 Docker Compose를 통해 재시작되었습니다."
    else
      echo "MongoDB 및 Redis 재시작에 실패했습니다."
      exit 1
    fi
  else
    echo "docker-compose.yaml 파일을 찾을 수 없습니다: $DOCKER_COMPOSE_DIR/docker-compose.yaml"
    exit 1
  fi

  # Restart PM2 managed services
  for service in "$PM2_BACKEND_NAME" "$PM2_FRONTEND_NAME"; do
    if pm2 list | grep -q "$service"; then
      echo "$service 재시작 중..."
      pm2 restart "$service"
    fi
  done

  # If you need to rebuild frontend in prod mode
  if [ "$MODE" = "prod" ]; then
    echo "프론트엔드 프로덕션 빌드를 재시작합니다..."
    cd "$FRONTEND_DIR"
    npm run build
    pm2 restart "$PM2_FRONTEND_NAME"
    cd ..
  fi

  echo "모든 서비스가 재시작되었습니다."
  pm2 list
}

status_services() {
  echo "서비스 상태를 확인합니다..."

  # Status of Docker Compose managed services
  echo "MongoDB 및 Redis 상태 (Docker Compose):"
  if [ -f "$DOCKER_COMPOSE_DIR/docker-compose.yaml" ]; then
    docker-compose -f "$DOCKER_COMPOSE_DIR/docker-compose.yaml" ps
  else
    echo "docker-compose.yaml 파일을 찾을 수 없습니다: $DOCKER_COMPOSE_DIR/docker-compose.yaml"
  fi

  # Status of PM2 managed services
  echo "PM2 관리 서비스 상태:"
  pm2 list
  
  echo "\n포트 사용 현황:"
  echo "MongoDB (27017):" $(lsof -i:27017 | grep LISTEN || echo "미사용")
  echo "Redis (6379):" $(lsof -i:6379 | grep LISTEN || echo "미사용")
  echo "Backend (5000):" $(lsof -i:5000 | grep LISTEN || echo "미사용")
  echo "Frontend (3000):" $(lsof -i:3000 | grep LISTEN || echo "미사용")
}

# 명령어 처리
case "$1" in
  start)
    start_services
    ;;
  stop)
    stop_services
    ;;
  restart)
    restart_services
    ;;
  status)
    status_services
    ;;
  *)
    echo "사용법: ./run.sh {start|stop|restart|status} [mode]"
    echo "mode 옵션: dev (기본값) | prod"
    exit 1
    ;;
esac