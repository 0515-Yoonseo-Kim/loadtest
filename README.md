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

## 1. 필수 환경 설치 및 환경 변수 설정 가이드
**환경 변수(Environment Variables)** 설정 방법에 대한 가이드입니다. 실제로 운영하는 환경에 따라 변경을 해야 동작할 수 있습니다.(로컬에서 개발/수정하는 것을 기준으로 작성이 되었고 원하는 환경에 따라 적절하게 수정해야 합니다.)
**MongoDB**, **Redis**, **OpenAI API** 등 외부 서비스와 연동하기 위해 여러 개의 환경 변수를 사용합니다.  
개발 환경의 차이로 인한 문제를 최대한 커버하기 위해서 `docker-compose.yaml`파일로 컨테이너를 띄울때 문제가 없도록 환경변수 위치등을 설정하였습니다.

### 1.1 필수 설치 및 버전
- **Docker** `v20` 이상
- **Docker Compose** `v2` 이상
- **Node.js** 최소 `v18.17.0` 이상의 이미지
  
### 1.2 환경 변수 파일 입력 가이드
#### MongoDB 관련 환경 변수 
```ini
# /loadtest/.env
MONGO_INITDB_ROOT_USERNAME=username
MONGO_INITDB_ROOT_PASSWORD=password
```
#### node.js 관련 환경 변수
암호호 키 랜덤 생성 권장 `openssl rand -hex 32`

```ini
# /loadtest/loadtest-backend/.env
MONGO_URI=mongodb://<username>:<password>@mongo:27017/bootcampchat?authSource=admin # 설정한 DB 유저이름, 패스워드 입력
JWT_SECRET=your_jwt_secret
REDIS_HOST=localhost
REDIS_PORT=6379
OPENAI_API_KEY=your_openai_key
ENCRYPTION_KEY=your_encryption_key
PASSWORD_SALT=your_salt_key
```

#### 리액트 환경 변수
node.js와 같은 암호화 키 설정 해야함
goorm vapor 패키지를 사용하기 위해서 access token을 요청해야함. [링크](https://vapor.goorm.io/guides/installation) 참고해서 작성 

```ini
# /loadtest/loadtest-frontend/.env.local
NEXT_PUBLIC_API_URL=http://localhost:5000
NEXT_PUBLIC_ENCRYPTION_KEY=your_encryption_key
NEXT_PUBLIC_PASSWORD_SALT=your_salt_key
```

```ini
# /loadtest/loadtest-frontend/.npmrc

# goorm-dev 패키지를 GitHub Packages에서 설치하기 위한 설정
# access token 발급 필요: https://vapor.goorm.io/guides/installation 참고

@goorm-dev:registry=https://npm.pkg.github.com/
//npm.pkg.github.com/:_authToken=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

```


### 1.3 실행 및 종료 커맨드

필요한 환경변수를 모두 입력하고 프로젝트 루트에서 해당 커맨드를 실행하면 실행됨
```sh
docker-compose up -d
docker-compose down
```
## 2. 아키텍처 설명
### 2.1 개발용 단일 서버 배포
![개발서버아키텍쳐그림 drawio](https://github.com/user-attachments/assets/22fcd52e-dc0e-44e0-8a35-b321740c95e7)
### 2.2 프로덕션 용 서버 배포

