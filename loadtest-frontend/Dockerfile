FROM node:18-alpine

WORKDIR /app

# npm 인증 토큰을 위한 ARG 추가
ARG NPM_TOKEN
ENV NPM_TOKEN=${NPM_TOKEN}

# npmrc 파일 복사
COPY .npmrc /root/.npmrc

# 패키지 파일 복사
COPY package.json package-lock.json ./

# npm 캐시 삭제 및 의존성 설치
RUN npm cache clean --force && npm install --legacy-peer-deps &&  npm install core-js-pure@latest --save

# 소스 코드 복사
COPY . .

# Next.js 빌드
RUN npm run build

# 서비스 실행 포트
EXPOSE 3000

# Next.js 앱 실행
CMD ["npm", "start"]
