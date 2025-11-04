const redisClient = require("../config/redisConnection");

/**
 * Fetch data from Redis by key
 * @param {string} key
 * @returns {Promise<any>} Parsed JSON data or null
 */
async function getFromRedis(key) {
    const data = await redisClient.get(key);
    return data ? JSON.parse(data) : null;
}

/**
 * Store data in Redis with TTL (in seconds)
 * @param {string} key
 * @param {any} value
 * @param {number} ttlSeconds
 */
async function setToRedis(key, value, ttlSeconds = null) {
    if (ttlSeconds) {
        // Set with expiration
        await redisClient.setEx(key, ttlSeconds, JSON.stringify(value));
    } else {
        // Set without expiration (infinite TTL)
        await redisClient.set(key, JSON.stringify(value));
    }
}


async function delFromRedis(key) {
    await redisClient.del(key);
}

module.exports = {
    getFromRedis,
    setToRedis,
    delFromRedis,
};
