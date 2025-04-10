# loadtest

부하테스트 후속 프로젝트
해당 레포지토리의 코드를 수정했습니다. [https://github.com/extinctmule/ktb-BootcampChat]

## 0. 프로젝트 개요

- **목적**:
  - 부하테스트 복기
  - 스트레스 테스트/모니터링 고도화
  - 최소한의 코드 수정으로 아키텍처 최적화 목표
  - [대회](https://gem-waste-46b.notion.site/16f5b5b9a26d802fbe43e8a7828078e9?pvs=4)때보다 더 적은 인스턴스를 사용해 동일 수준의 부하 도달을 목표로 실험 진행
- **개선 방향**:
  - `local`, `dev`, `prod` 등 **환경별 파이프라인 작성**
  - E2E 스트레스 테스트 구조 분리 및 정리 [https://github.com/0515-Yoonseo-Kim/loadtest-e2e]
  - 관측지표 다양화
  - 부하테스트 시나리오 다양화 및 개선
---
## 0. 필수 환경 및 환경 변수 설정 가이드
**환경 변수(Environment Variables)** 설정 방법에 대한 가이드입니다. 실제로 운영하는 환경에 따라 변경을 해야 동작할 수 있습니다.(로컬에서 개발/수정하는 것을 기준으로 작성이 되었고 원하는 환경에 따라 적절하게 수정해야 합니다.)
**MongoDB**, **Redis**, **OpenAI API** 등 외부 서비스와 연동하기 위해 여러 개의 환경 변수를 사용합니다.  
개발 환경의 차이로 인한 문제를 최대한 커버하기 위해서 `docker-compose.yaml`파일로 컨테이너를 띄울때 문제가 없도록 환경변수 위치등을 설정하였습니다.

### 각 환경 변수 설명
#### MongoDB 관련 환경 변수 
```ini
# /loadtest/.env
MONGO_INITDB_ROOT_USERNAME=username
MONGO_INITDB_ROOT_PASSWORD=password
```
#### node.js 관련 환경 변수
ENCRYPTION_KEY는 `openssl rand -hex 32` 랜덤 생성 권장

```ini
# /loadtest/loadtest-backend/.env
MONGO_URI=mongodb_url
JWT_SECRET=your_jwt_secret
REDIS_HOST=localhost
REDIS_PORT=6379
OPENAI_API_KEY=your_openai_key
ENCRYPTION_KEY=your_encryption_key
PASSWORD_SALT=your_salt_key
```

#### 프론트엔드 환경 변수
| 변수명           | 설명                                                                    |
|-----------------|-------------------------------------------------------------------------|
| **NEXT_PUBLIC_API_URL**   | 백엔드 API 서버 주소 (예: http://localhost:5000 또는 도메인)           |
| **NEXT_PUBLIC_ENCRYPTION_KEY**  | 특정 암호화 로직에 사용하는 키 (백엔드 환경 변수와 동일)                          |
| **NEXT_PUBLIC_PASSWORD_SALT**  | 비밀번호 해싱 로직이 (백엔드 환경 변수와 동일)      |


## 1. 로컬 개발 환경(직접 실행 시)
필요에 따라 실제 값(유저, 비밀번호, API 키)을 알맞게 수정하세요.
### 1.1 환경 변수 설정

1) loadtest/.env
```ìni
MONGO_INITDB_ROOT_USERNAME=your_mongo_user
MONGO_INITDB_ROOT_PASSWORD=your_mongo_passsword
```

3) loadtest/loadtest-backend/.env

```ini
# 예시: .env 파일 내용

# MongoDB 접속 주소
MONGO_URI=mongodb://<your_mongo_user>:<your_mongo_password>@localhost:27017/bootcampchat?authSource=admin

# JWT 발급 시 사용할 시크릿 키
JWT_SECRET=your_jwt_secret

# Redis 접속 정보
REDIS_HOST=localhost
REDIS_PORT=6379

# OpenAI API 키
OPENAI_API_KEY=your_openai_api_key

# 사용자 이메일 암호화 등에 사용될 AES-256 암호화 키(64자리 hex)
ENCRYPTION_KEY=your_encryption_key

# 비밀번호 해싱(salt)용 문자열(32자리 hex)
PASSWORD_SALT=your_salt_key
```

3) loadtest/loadtest-frontend/.env.local

```ìni
NEXT_PUBLIC_API_URL=http://localhost:5000
NEXT_PUBLIC_ENCRYPTION_KEY=your_encryption_key
NEXT_PUBLIC_PASSWORD_SALT=your_salt_key
```
### 1.2 실행 커맨드
```sh
./run.sh start <모드>
./run.sh stop <모드>
./run.sh restart <모드>
```
모드는 `dev` `prod` 2가지이고 입력이 들어오지 않을 시 기본 값은 dev이다.

## 2. Docker Compose 환경에서 실행 시

### 2.1 docker-compose.yml에서 env_file 사용

`docker-compose.yml`에 아래와 같이 **env_file**을 설정해두었다면,

```yaml
services:
  backend:
    build:
      context: ./loadtest-backend
      dockerfile: Dockerfile
    container_name: loadtest-backend-server
    restart: always
    # <-- env_file 옵션
    env_file:
      - ./loadtest-backend/.env
    ports:
      - "5000:5000"
    depends_on:
      - mongo
      - redis
  # ...
```

- `env_file`에 지정된 경로(`./loadtest-backend/.env`)의 파일이 **컨테이너 환경 변수**로 로드됩니다.
- Docker Compose가 **컨테이너** 내부에 `.env` 파일을 직접 복사해 넣는 것은 아니지만, **컨테이너 실행 시점**에 `process.env`에 값을 주입합니다.
- 따라서 `loadtest-backend/.env` 파일에 위에서 언급한 환경 변수를 동일하게 넣어주시면 됩니다.

```ini
# 예시: loadtest-backend/.env (Docker Compose에서 사용)

MONGO_URI=mongodb://<유저>:<비밀번호>@mongo:27017/bootcampchat?authSource=admin
JWT_SECRET=your_jwt_secret
REDIS_HOST=redis
REDIS_PORT=6379
OPENAI_API_KEY=your_openai_api_key
ENCRYPTION_KEY=your_encryption_key
PASSWORD_SALT=your_salt_key
```

- 이때, **MongoDB**는 `mongo`라는 서비스명으로 접근하고,  
- **Redis**는 `redis`라는 서비스명으로 접근해야 합니다. (Compose가 내부 네트워크를 자동으로 설정해줌)

### 2.2 Docker Compose 네트워크에서의 주의사항

- **`localhost`** 는 컨테이너 자기 자신을 의미하므로, 다른 컨테이너(DB, Redis 등)에 접속할 때는 반드시 **서비스명**을 사용해야 합니다.
- 예: `MONGO_URI=mongodb://<유저>:<비번>@mongo:27017/<DB>?authSource=admin`

### 2.3 실행 예시

```sh
docker-compose up -d
docker-compose down
```

---

## 4. 주의 사항
 - **Docker Compose**로 배포 시, `.env` 파일 내용이 자동으로 이미지 안에 포함되지 않고, **실행 시점**에 주입됩니다.  
