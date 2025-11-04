const { Pool } = require('pg');

// Create a connection pool for main database
const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'your_user',
    password: process.env.DB_PASSWORD || 'your_password',
    database: process.env.DB_NAME || 'your_db',
    port: process.env.DB_PORT || 5432,
});

pool.connect()
    .then(() => console.log('✅ Connected to PostgreSQL database'))
    .catch(err => console.error('❌ Connection error', err.stack));

// Export both the pool and a destructured object for compatibility
module.exports = pool;
module.exports.pool = pool;
