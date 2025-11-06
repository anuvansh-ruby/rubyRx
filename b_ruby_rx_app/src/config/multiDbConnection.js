const { Pool } = require('pg');

// Main Application Database Pool
const mainPool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'your_user',
    password: process.env.DB_PASSWORD || 'your_password',
    database: process.env.DB_NAME || 'your_db',
    port: process.env.DB_PORT || 5432,
    max: 50, // Maximum number of clients in the pool
    idleTimeoutMillis: 30000, // How long a client is allowed to remain idle
    connectionTimeoutMillis: 10000, // How long to wait before timing out when connecting a new client
});

// Medicine Database Pool
const medicinePool = new Pool({
    host: process.env.MEDICINE_DB_HOST || 'localhost',
    user: process.env.MEDICINE_DB_USER || 'your_user',
    password: process.env.MEDICINE_DB_PASSWORD || 'your_password',
    database: process.env.MEDICINE_DB_NAME || 'your_db',
    port: process.env.MEDICINE_DB_PORT || 5432,
    max: 50, // Smaller pool for medicine database
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 10000,
});

// Initialize connections and handle events
const initializeDatabases = async () => {
    try {
        // Test main database connection
        const mainClient = await mainPool.connect();
        console.log('✅ Connected to Main Application Database');
        mainClient.release();

        // Test medicine database connection
        const medicineClient = await medicinePool.connect();
        console.log('✅ Connected to Medicine Database');
        medicineClient.release();

        // Handle connection errors
        mainPool.on('error', (err) => {
            console.error('❌ Main Database Pool Error:', err);
        });

        medicinePool.on('error', (err) => {
            console.error('❌ Medicine Database Pool Error:', err);
        });

        // Handle pool connection events
        mainPool.on('connect', (client) => {
            console.log('🔗 New main database client connected');
        });

        medicinePool.on('connect', (client) => {
            console.log('🔗 New medicine database client connected');
        });

        // Handle pool removal events
        mainPool.on('remove', (client) => {
            console.log('🔌 Main database client removed');
        });

        medicinePool.on('remove', (client) => {
            console.log('🔌 Medicine database client removed');
        });

    } catch (err) {
        console.error('❌ Database initialization error:', err.stack);
        process.exit(1);
    }
};

// Graceful shutdown
const closeDatabases = async () => {
    try {
        console.log('🔄 Closing database connections...');
        await mainPool.end();
        await medicinePool.end();
        console.log('✅ Database connections closed');
    } catch (err) {
        console.error('❌ Error closing database connections:', err);
    }
};

// Handle process termination
process.on('SIGINT', async () => {
    console.log('\n🛑 Received SIGINT, closing database connections...');
    await closeDatabases();
    process.exit(0);
});

process.on('SIGTERM', async () => {
    console.log('\n🛑 Received SIGTERM, closing database connections...');
    await closeDatabases();
    process.exit(0);
});

// Export pools and utility functions
module.exports = {
    // Main database pool for application data
    mainPool,

    // Medicine database pool for medicine search data
    medicinePool,

    // Legacy export for backward compatibility
    pool: mainPool,

    // Utility functions
    initializeDatabases,
    closeDatabases,

    // Helper function to get appropriate pool
    getPool: (database = 'main') => {
        switch (database.toLowerCase()) {
            case 'medicine':
                return medicinePool;
            case 'main':
            default:
                return mainPool;
        }
    },

    // Health check function
    healthCheck: async () => {
        try {
            const mainClient = await mainPool.connect();
            const medicineClient = await medicinePool.connect();

            // Simple query to test connections
            await mainClient.query('SELECT 1');
            await medicineClient.query('SELECT 1');

            mainClient.release();
            medicineClient.release();

            return {
                main: 'connected',
                medicine: 'connected',
                status: 'healthy'
            };
        } catch (error) {
            return {
                main: mainPool._connected ? 'connected' : 'disconnected',
                medicine: medicinePool._connected ? 'connected' : 'disconnected',
                status: 'unhealthy',
                error: error.message
            };
        }
    }
};