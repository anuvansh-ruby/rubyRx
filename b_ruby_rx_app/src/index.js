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
    try {
        // Initialize both database connections
        await initializeDatabases();

        // Start the server
        app.listen(PORT, '0.0.0.0', () => {
            console.log(`Server running on port ${PORT}`);
            console.log(`🏥 Main Database: ${process.env.DB_NAME || 'ruby_ai_db'}`);
            console.log(`💊 Medicine Database: ${process.env.MEDICINE_DB_NAME || process.env.DB_NAME || 'ruby_ai_db'}`);
        });
    } catch (error) {
        console.error('❌ Failed to start server:', error);
        process.exit(1);
    }
};

startServer();
