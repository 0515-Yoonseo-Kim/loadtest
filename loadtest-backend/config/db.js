import mongoose from "mongoose";

export default async function connectDB() {
  try {
    const mongoURI = process.env.MONGO_URI;
    if (!mongoURI) {
      throw new Error("MongoDB URI is not defined in environment variables.");
    }

    await mongoose.connect(mongoURI, {
      maxPoolSize: 100, // 최대 연결 풀 크기 설정
      serverSelectionTimeoutMS: 5000, // 5초 이내에 서버 선택 실패 시 에러 발생
      socketTimeoutMS: 10000, // 소켓 타임아웃 설정
      readPreference: "secondaryPreferred", // 읽기 우선순위 설정 (샤딩 시)
    });

    console.log("MongoDB connected successfully.");
  } catch (error) {
    console.error("MongoDB connection error:", error);
    throw error;
  }
}
