const { createClient } = require("redis");

const redisClient = createClient({
    url: process.env.REDIS_URL || "redis://127.0.0.1:6379",
});

redisClient.on("error", (err) => console.error("❌ Redis Client Error:", err));

redisClient.on("connect", () => {
    console.log("🔌 Redis client is connecting...");
});

redisClient.on("ready", () => {
    console.log("✅ Redis client connected successfully!");
});

(async () => {
    await redisClient.connect();
})();

module.exports = redisClient;
