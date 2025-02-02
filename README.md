# loadtest

부하테스트 후속 프로젝트

---

# Environment Variables 설정 가이드
**환경 변수(Environment Variables)** 설정 방법에 대한 예시 가이드(README.md 일부)입니다. 실제로 사용하시는 레포지토리나 프로젝트 구조에 맞춰 적절히 수정해서 사용하세요.

이 프로젝트는 **MongoDB**, **Redis**, **OpenAI API** 등 외부 서비스와 연동하기 위해 여러 개의 환경 변수를 사용합니다.  
개발 환경의 차이로 인한 문제를 최대한 커버하기 위해서 `docker-compose.yaml`파일로 컨테이너를 띄울때 문제가 없도록 환경변수 위치등을 설정하였습니다.

### 각 환경 변수 설명
#### 백엔드 환경 변수
| 변수명           | 설명                                                                    |
|-----------------|-------------------------------------------------------------------------|
| **MONGO_URI**   | MongoDB 연결 문자열 (접속 계정, DB 이름, 호스트:포트 등 포함)           |
| **JWT_SECRET**  | JWT(Json Web Token) 발급 시 사용되는 시크릿 키                          |
| **REDIS_HOST**  | Redis 서버가 위치한 호스트(도커 환경에서는 보통 서비스명 `redis`)       |
| **REDIS_PORT**  | Redis 서버 포트. 기본적으로 `6379`                                     |
| **OPENAI_API_KEY** | OpenAI GPT 등 API를 사용하기 위한 API 키                              |
| **ENCRYPTION_KEY** | 사용자 이메일 암호화 등에 사용하는 **AES-256** 키(64자리 hex)        |
| **PASSWORD_SALT**  | 비밀번호 해싱(salt)에 사용될 문자열(32자리 hex)                      |
#### 프론트엔드 환경 변수
| 변수명           | 설명                                                                    |
|-----------------|-------------------------------------------------------------------------|
| **NEXT_PUBLIC_API_URL**   | 백엔드 API 서버 주소 (예: http://localhost:5000 또는 도메인)           |
| **NEXT_PUBLIC_ENCRYPTION_KEY**  | 특정 암호화 로직에 사용하는 키 (브라우저 단 암호화가 필요한 경우)                          |
| **NEXT_PUBLIC_PASSWORD_SALT**  | 비밀번호 해싱 로직이 프론트에도 필요할 때 사용      |

### 데이터베이스 환경 변수 
	
| 변수명           | 설명                                                                    |
|-----------------|-------------------------------------------------------------------------|
| **MONGO_INITDB_ROOT_USERNAME**   | 초기 루트 사용자명           |
| **MONGO_INITDB_ROOT_PASSWORD**  | MongoDB 초기 루트 사용자 비밀번호                         |

## 1. 로컬 개발 환경(직접 실행 시)
필요에 따라 실제 값(유저, 비밀번호, API 키)을 알맞게 수정하세요.

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

```bash
docker-compose up -d
docker-compose down
```

---

## 4. 주의 사항
 - **Docker Compose**로 배포 시, `.env` 파일 내용이 자동으로 이미지 안에 포함되지 않고, **실행 시점**에 주입됩니다.  
