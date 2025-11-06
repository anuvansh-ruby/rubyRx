const { createClient } = require("redis");

const redisClient = createClient({
    url: process.env.REDIS_URL || "redis://127.0.0.1:6379",
    socket: {
        reconnectStrategy: (retries) => {
            if (retries > 10) {
                console.error("❌ Redis: Too many retries, giving up");
                return new Error("Too many retries");
            }
            return Math.min(retries * 100, 3000);
        },
        connectTimeout: 10000
    }
});

let isConnected = false;

redisClient.on("error", (err) => {
    console.error("❌ Redis Client Error:", err.message);
    isConnected = false;
});

redisClient.on("connect", () => {
    console.log("🔌 Redis client is connecting...");
});

redisClient.on("ready", () => {
    console.log("✅ Redis client connected successfully!");
    isConnected = true;
});

redisClient.on("reconnecting", () => {
    console.log("🔄 Redis client is reconnecting...");
});

// Connect with error handling
const connectRedis = async () => {
    try {
        await redisClient.connect();
    } catch (err) {
        console.error("⚠️  Redis connection failed, continuing without Redis:", err.message);
    }
};

// Export both client and connection function
module.exports = redisClient;
module.exports.connectRedis = connectRedis;
module.exports.isConnected = () => isConnected;
