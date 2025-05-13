// 기본 키와 솔트 (개발 환경용)
const DEFAULT_ENCRYPTION_KEY = "a".repeat(64); // 32바이트를 hex로 표현
const DEFAULT_PASSWORD_SALT = "b".repeat(32); // 16바이트를 hex로 표현

require("dotenv").config();

const isCluster = process.env.REDIS_CLUSTER_MODE === "true";
const redisPassword = process.env.REDIS_PASSWORD;

// 클러스터 호스트 문자열 → 배열로 변환
const redisClusterNodes = isCluster
  ? (process.env.REDIS_CLUSTER_HOSTS || "")
      .split(",")
      .filter(Boolean)
      .map((host) => ({
        host: host.trim(),
        port: parseInt(process.env.REDIS_CLUSTER_PORT || "6379", 10),
      }))
  : [];

module.exports = {
  isCluster,
  redisClusterNodes,
  redisHost: process.env.REDIS_HOST,
  redisPort: parseInt(process.env.REDIS_PORT),
  mongoURI: process.env.MONGO_URI,
  jwtSecret: process.env.JWT_SECRET,
  openaiApiKey: process.env.OPENAI_API_KEY,
  encryptionKey: process.env.ENCRYPTION_KEY,
  passwordSalt: process.env.PASSWORD_SALT,
};
