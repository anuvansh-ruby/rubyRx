# Ruby RX App - GCP Deployment Guide

This repository contains the Ruby RX application with complete Docker and Google Cloud Platform (GCP) deployment setup.

## 📁 Project Structure

```
rubyRx/
├── b_ruby_rx_app/              # Node.js backend application
├── ruby_rx_flutter/            # Flutter mobile application
├── Dockerfile                  # Docker configuration for GCP
├── docker-compose.yml          # Local development setup
├── cloud-run-service.yaml      # Cloud Run service configuration
├── deploy-to-gcp.sh            # GCP deployment script
└── .dockerignore              # Docker ignore file
```

## 🚀 Quick Start

### Local Development with Docker Compose

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd rubyRx
   ```

2. **Set up environment variables**
   ```bash
   cp b_ruby_rx_app/.env.example b_ruby_rx_app/.env
   # Edit the .env file with your local configuration
   ```

3. **Start the development environment**
   ```bash
   docker-compose up -d
   ```

4. **Access the services**
   - API: http://localhost:5500
   - pgAdmin: http://localhost:8080 (admin@rubyRx.com / admin123)
   - Redis Commander: http://localhost:8081

### Production Deployment to GCP

## 🔧 Prerequisites

1. **Install required tools:**
   - [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
   - [Docker](https://docs.docker.com/get-docker/)

2. **GCP Setup:**
   - Create a GCP project
   - Enable billing
   - Install and configure gcloud CLI

## 📋 Environment Variables

### Required Environment Variables

The application requires the following environment variables:

#### Database Configuration
- `DB_HOST` - Main PostgreSQL host
- `DB_USER` - Main PostgreSQL username  
- `DB_PASSWORD` - Main PostgreSQL password
- `DB_NAME` - Main PostgreSQL database name
- `DB_PORT` - Main PostgreSQL port (default: 5432)

#### Medicine Database Configuration
- `MEDICINE_DB_HOST` - Medicine PostgreSQL host
- `MEDICINE_DB_USER` - Medicine PostgreSQL username
- `MEDICINE_DB_PASSWORD` - Medicine PostgreSQL password
- `MEDICINE_DB_NAME` - Medicine PostgreSQL database name
- `MEDICINE_DB_PORT` - Medicine PostgreSQL port (default: 5432)

#### Redis Configuration
- `REDIS_URL` - Redis connection string

#### Authentication & Security
- `JWT_SECRET` - JWT secret key for token signing

#### OAuth Configuration
- `GOOGLE_CLIENT_ID` - Google OAuth client ID
- `GOOGLE_CLIENT_SECRET` - Google OAuth client secret
- `GOOGLE_REDIRECT_URI` - Google OAuth redirect URI
- `LINKEDIN_CLIENT_ID` - LinkedIn OAuth client ID
- `LINKEDIN_CLIENT_SECRET` - LinkedIn OAuth client secret
- `LINKEDIN_REDIRECT_URI` - LinkedIn OAuth redirect URI

#### Email Configuration
- `EMAIL_USER` - Gmail address for sending emails
- `GOOGLE_EMAIL_USER` - Gmail address
- `GOOGLE_APP_PASSWORD` - Gmail app password

#### External APIs
- `WASENDER_API_KEY` - WhatsApp sender API key
- `GOOGLE_APPLICATION_CREDENTIALS` - Path to GCP service account JSON
- `GOOGLE_CLOUD_PROJECT_ID` - GCP project ID
- `GOOGLE_GENERATIVE_AI_API_KEY` - Google AI API key

## 🌐 GCP Deployment

### Automated Deployment

1. **Set environment variables:**
   ```bash
   export GCP_PROJECT_ID="your-gcp-project-id"
   export GCP_REGION="us-central1"
   ```

2. **Run the deployment script:**
   ```bash
   ./deploy-to-gcp.sh
   ```

### Manual Deployment Steps

1. **Build and push Docker image:**
   ```bash
   # Set your project ID
   PROJECT_ID="your-gcp-project-id"
   
   # Build the image
   docker build -t gcr.io/${PROJECT_ID}/ruby-rx-app:latest .
   
   # Push to GCR
   docker push gcr.io/${PROJECT_ID}/ruby-rx-app:latest
   ```

2. **Create Cloud SQL instances:**
   ```bash
   # Main database
   gcloud sql instances create ruby-rx-main-db \
       --database-version=POSTGRES_14 \
       --tier=db-f1-micro \
       --region=us-central1
   
   # Medicine database
   gcloud sql instances create ruby-rx-medicine-db \
       --database-version=POSTGRES_14 \
       --tier=db-f1-micro \
       --region=us-central1
   ```

3. **Create Redis instance:**
   ```bash
   gcloud redis instances create ruby-rx-redis \
       --size=1 \
       --region=us-central1
   ```

4. **Create secrets in Secret Manager:**
   ```bash
   # Enable Secret Manager API
   gcloud services enable secretmanager.googleapis.com
   
   # Create secrets (replace with actual values)
   echo -n "your-db-username" | gcloud secrets create db-username --data-file=-
   echo -n "your-db-password" | gcloud secrets create db-password --data-file=-
   # ... create all required secrets
   ```

5. **Deploy to Cloud Run:**
   ```bash
   gcloud run services replace cloud-run-service.yaml --region=us-central1
   ```

## 🔒 Security Configuration

### Secret Manager Setup

Create the following secrets in Google Secret Manager:

1. **Database Credentials:**
   - `db-credentials` - Main database credentials
   - `medicine-db-credentials` - Medicine database credentials

2. **Application Secrets:**
   - `app-secrets` - JWT secret
   - `oauth-credentials` - OAuth client IDs and secrets
   - `email-credentials` - Gmail credentials
   - `api-keys` - External API keys

3. **GCP Service Account:**
   - `gcp-service-account-key` - Service account JSON key

### IAM Roles

The Cloud Run service account needs:
- `roles/cloudsql.client` - Cloud SQL access
- `roles/redis.editor` - Redis access
- `roles/secretmanager.secretAccessor` - Secret Manager access
- `roles/ml.aiPlatform.user` - AI Platform access
- `roles/vision.annotator` - Vision API access

## 📊 Monitoring & Logging

### Health Checks

The application includes health check endpoints:
- `/api/health/databases` - Database connectivity check

### Cloud Run Configuration

- **Memory:** 2Gi
- **CPU:** 2 vCPU
- **Concurrency:** 1000 requests
- **Timeout:** 300 seconds
- **Min instances:** 1
- **Max instances:** 10

## 🔧 Local Development

### Using Docker Compose

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f ruby-rx-app

# Stop services
docker-compose down

# Rebuild and restart
docker-compose up -d --build
```

### Database Management

- **pgAdmin:** http://localhost:8080
  - Email: admin@rubyRx.com
  - Password: admin123

- **Redis Commander:** http://localhost:8081

## 🐛 Troubleshooting

### Common Issues

1. **Database Connection Errors:**
   - Check Cloud SQL instance status
   - Verify Cloud SQL Proxy configuration
   - Ensure proper IAM permissions

2. **Redis Connection Issues:**
   - Verify Redis instance is running
   - Check VPC connectivity

3. **Authentication Errors:**
   - Verify service account permissions
   - Check secret values in Secret Manager

### Logs

```bash
# View Cloud Run logs
gcloud logs read --service=ruby-rx-app --region=us-central1

# Follow logs in real-time
gcloud logs tail --service=ruby-rx-app --region=us-central1
```

## 📖 API Documentation

### Health Check Endpoints

- `GET /api/health/databases` - Database connectivity status

### Authentication Endpoints

- `POST /api/v1/auth/google` - Google OAuth authentication
- `POST /api/v1/auth/linkedin` - LinkedIn OAuth authentication

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally with Docker Compose
5. Submit a pull request

## 📝 License

[Add your license information here]

## 📧 Support

For support and questions, please [create an issue](https://github.com/your-repo/issues) or contact the development team.