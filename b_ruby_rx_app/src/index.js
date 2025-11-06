require('dotenv').config();
const express = require('express');
const cors = require('cors');
const pool = require('./config/dbConnection');
const { initializeDatabases, healthCheck } = require('./config/multiDbConnection');
const redisClient = require('./config/redisConnection');
const validateRequests = require('./middleware/validateRequests');
const { logRequest, logResponse } = require('./middleware/requestLogger');

const dns = require('node:dns');
const os = require('node:os');

// const options = { family: 4 };

// dns.lookup(os.hostname(), options, (err, addr) => {
//     if (err) {
//         console.error(err);
//     } else {
//         console.log(`IPv4 address: ${addr}`);
//     }
// });

const app = express();

app.use(cors());
app.use(express.json());
app.use(cors({ origin: '*' }));

// Add request and response logging middleware
app.use(logRequest);
app.use(logResponse);

app.use('/api/v1', validateRequests.validateRequest);

require('./routes/routes')(app);

// Basic health check endpoint (fast response for startup probes)
app.get('/health', (req, res) => {
    res.json({
        status: 'SUCCESS',
        message: 'Server is running',
        timestamp: new Date().toISOString()
    });
});

// Add database health check endpoint
app.get('/api/health/databases', async (req, res) => {
    try {
        const dbStatus = await healthCheck();
        res.json({
            status: 'SUCCESS',
            message: 'Database health check completed',
            data: dbStatus
        });
    } catch (error) {
        res.status(500).json({
            status: 'FAILURE',
            message: 'Database health check failed',
            error: error.message
        });
    }
});

const PORT = process.env.PORT || 5500;

// Initialize databases and start server
const startServer = async () => {
    // Start the server FIRST to pass health checks
    const server = app.listen(PORT, '0.0.0.0', () => {
        console.log(`✅ Server listening on port ${PORT}`);
        console.log(`🏥 Main Database: ${process.env.DB_NAME || 'ruby_ai_db'}`);
        console.log(`💊 Medicine Database: ${process.env.MEDICINE_DB_NAME || process.env.DB_NAME || 'ruby_ai_db'}`);
    });

    // Then initialize connections in the background
    try {
        console.log('🔄 Initializing database connections...');
        await initializeDatabases();
        
        // Initialize Redis connection (non-blocking)
        const { connectRedis } = require('./config/redisConnection');
        await connectRedis();
    } catch (error) {
        console.error('⚠️  Warning: Some connections failed during initialization:', error.message);
        console.log('ℹ️  Server will continue running with degraded functionality');
        // Don't exit - let the server handle requests with degraded functionality
    }
};

startServer();
