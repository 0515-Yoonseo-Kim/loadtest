const Redis = require("ioredis");
const {
  isCluster,
  redisHost,
  redisPort,
  redisClusterNodes,
} = require("../config/keys");

class RedisClient {
  constructor() {
    this.client = null;
    this.connected = false;
    this.isCluster = isCluster;
  }

  async connect() {
    if (this.connected && this.client) {
      return this.client;
    }

    try {
      console.log("Connecting to Redis...");

      if (this.isCluster && redisClusterNodes?.length) {
        console.log("Using Redis Cluster...");
        this.client = new Redis.Cluster(redisClusterNodes, {
          redisOptions: {
            readOnly: true,
            retryStrategy: (times) => {
              if (times > 5) {
                console.error("Exceeded maximum retries for Redis Cluster");
                return null;
              }
              return Math.min(times * 100, 2000);
            },
          },
        });
      } else {
        console.log("Using single-node Redis...");
        this.client = new Redis({
          host: redisHost,
          port: redisPort,
          retryStrategy: (times) => {
            if (times > 5) {
              console.error("Exceeded maximum retries for Redis");
              return null;
            }
            return Math.min(times * 100, 2000);
          },
        });
      }

      this.client.on("connect", async () => {
        try {
          const pong = await this.client.ping();
          console.log("Redis responded to PING:", pong);
          this.connected = true;
        } catch (err) {
          console.error("Redis PING failed:", err);
          this.connected = false;
        }
      });

      this.client.on("error", (err) => {
        console.error("Redis Client Error:", err);
        this.connected = false;
      });

      return this.client;
    } catch (error) {
      console.error("Redis connection error:", error);
      this.connected = false;
      throw error;
    }
  }

  async set(key, value, options = {}) {
    try {
      await this.connect();
      const stringValue =
        typeof value === "object" ? JSON.stringify(value) : String(value);
      if (options.ttl) {
        return await this.client.set(key, stringValue, "EX", options.ttl);
      }
      return await this.client.set(key, stringValue);
    } catch (error) {
      console.error("Redis set error:", error);
      throw error;
    }
  }

  async get(key) {
    try {
      await this.connect();
      const value = await this.client.get(key);
      if (!value) return null;
      try {
        return JSON.parse(value);
      } catch {
        return value;
      }
    } catch (error) {
      console.error("Redis get error:", error);
      throw error;
    }
  }

  async del(key) {
    try {
      await this.connect();
      return await this.client.del(key);
    } catch (error) {
      console.error("Redis del error:", error);
      throw error;
    }
  }

  async lRange(key, start, end) {
    try {
      await this.connect();
      return await this.client.lrange(key, start, end);
    } catch (error) {
      console.error("Redis lRange error:", error);
      throw error;
    }
  }

  async scanAllKeys(pattern) {
    try {
      await this.connect();
      let cursor = "0";
      let keys = [];

      do {
        const [nextCursor, foundKeys] = await this.client.scan(
          cursor,
          "MATCH",
          pattern,
          "COUNT",
          100
        );
        cursor = nextCursor;
        keys = keys.concat(foundKeys);
      } while (cursor !== "0");

      return keys;
    } catch (error) {
      console.error("Redis scanAllKeys error:", error);
      throw error;
    }
  }

  async lTrim(key, start, end) {
    try {
      await this.connect();
      return await this.client.ltrim(key, start, end);
    } catch (error) {
      console.error("Redis lTrim error:", error);
      throw error;
    }
  }

  async saveChatMessage(chatRoomId, message) {
    try {
      await this.connect();
      const key = `chat:${chatRoomId}`;
      const messageString =
        typeof message === "object" ? JSON.stringify(message) : message;

      await this.client.lpush(key, messageString);
      await this.lTrim(key, 0, 49);
      console.log(`Message saved in Redis (key: ${key})`);
    } catch (error) {
      console.error("Redis saveChatMessage error:", error);
      throw error;
    }
  }

  async getRecentChatMessages(chatRoomId, count = 50) {
    try {
      await this.connect();
      const key = `chat:${chatRoomId}`;
      const messages = await this.client.lrange(key, 0, count - 1);
      return messages.map((msg) => {
        try {
          return JSON.parse(msg);
        } catch {
          return msg;
        }
      });
    } catch (error) {
      console.error("Redis getRecentChatMessages error:", error);
      throw error;
    }
  }

  pipeline() {
    return this.client.pipeline();
  }

  async quit() {
    if (this.client) {
      try {
        await this.client.quit();
        console.log("Redis connection closed successfully");
        this.connected = false;
      } catch (error) {
        console.error("Redis quit error:", error);
        throw error;
      }
    }
  }

  async expire(key, ttl) {
    try {
      await this.connect();
      return await this.client.expire(key, ttl);
    } catch (error) {
      console.error("Redis expire error:", error);
      throw error;
    }
  }
}

module.exports = new RedisClient();
