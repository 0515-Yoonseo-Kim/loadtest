#!/bin/bash

CONTAINER_NAME="buha-backend"
LOG_GROUP="docker-stats"
LOG_STREAM="$(hostname)"


# 로그 스트림 생성
aws logs create-log-stream \
  --log-group-name "$LOG_GROUP" \
  --log-stream-name "$LOG_STREAM"

# 수집 루프
while true; do
  TIMESTAMP=$(date +%s%3N)
  STATS=$(docker stats "$CONTAINER_NAME" --no-stream --format "{{.Container}} CPU={{.CPUPerc}} MEM={{.MemUsage}}")

  # 이전 시퀀스 토큰 가져오기
  TOKEN=$(aws logs describe-log-streams \
    --log-group-name "$LOG_GROUP" \
    --log-stream-name-prefix "$LOG_STREAM" \
    --query "logStreams[0].uploadSequenceToken" \
    --output text)

  # 로그 이벤트 전송
  if [ "$TOKEN" = "None" ]; then
    aws logs put-log-events \
      --log-group-name "$LOG_GROUP" \
      --log-stream-name "$LOG_STREAM" \
      --log-events timestamp=$TIMESTAMP,message="$STATS"
  else
    aws logs put-log-events \
      --log-group-name "$LOG_GROUP" \
      --log-stream-name "$LOG_STREAM" \
      --log-events timestamp=$TIMESTAMP,message="$STATS" \
      --sequence-token "$TOKEN"
  fi

  sleep 60
done