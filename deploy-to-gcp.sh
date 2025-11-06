#!/bin/bash

# GCP Deployment Script for Ruby RX App
# Make sure to set these variables before running the script

set -e

# Configuration Variables
PROJECT_ID="${GCP_PROJECT_ID:-your-gcp-project-id}"
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="ruby-rx-app"
IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting Ruby RX App deployment to GCP${NC}"

# Check if required environment variables are set
if [ "$PROJECT_ID" = "your-gcp-project-id" ]; then
    echo -e "${RED}❌ Please set GCP_PROJECT_ID environment variable${NC}"
    exit 1
fi

# Authenticate with GCP (if not already authenticated)
echo -e "${YELLOW}🔐 Checking GCP authentication...${NC}"
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo -e "${YELLOW}Please authenticate with GCP:${NC}"
    gcloud auth login
fi

# Set the project
echo -e "${YELLOW}📋 Setting GCP project to ${PROJECT_ID}...${NC}"
gcloud config set project ${PROJECT_ID}

# Enable required APIs
echo -e "${YELLOW}🔧 Enabling required GCP APIs...${NC}"
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable redis.googleapis.com
gcloud services enable vision.googleapis.com
gcloud services enable aiplatform.googleapis.com

# Build the Docker image
echo -e "${YELLOW}🏗️  Building Docker image...${NC}"
docker build -t ${IMAGE_NAME}:latest .

# Push the image to Google Container Registry
echo -e "${YELLOW}📤 Pushing image to GCR...${NC}"
docker push ${IMAGE_NAME}:latest

# Create Cloud SQL instance (PostgreSQL) if it doesn't exist
echo -e "${YELLOW}🗄️  Setting up Cloud SQL instances...${NC}"
if ! gcloud sql instances describe ruby-rx-main-db --region=${REGION} >/dev/null 2>&1; then
    echo -e "${YELLOW}Creating main database instance...${NC}"
    gcloud sql instances create ruby-rx-main-db \
        --database-version=POSTGRES_14 \
        --tier=db-f1-micro \
        --region=${REGION} \
        --storage-auto-increase \
        --backup-start-time=03:00
fi

if ! gcloud sql instances describe ruby-rx-medicine-db --region=${REGION} >/dev/null 2>&1; then
    echo -e "${YELLOW}Creating medicine database instance...${NC}"
    gcloud sql instances create ruby-rx-medicine-db \
        --database-version=POSTGRES_14 \
        --tier=db-f1-micro \
        --region=${REGION} \
        --storage-auto-increase \
        --backup-start-time=04:00
fi

# Create Redis instance if it doesn't exist
echo -e "${YELLOW}📦 Setting up Redis instance...${NC}"
if ! gcloud redis instances describe ruby-rx-redis --region=${REGION} >/dev/null 2>&1; then
    echo -e "${YELLOW}Creating Redis instance...${NC}"
    gcloud redis instances create ruby-rx-redis \
        --size=1 \
        --region=${REGION} \
        --redis-version=redis_6_x
fi

# Create service account for Cloud Run
echo -e "${YELLOW}👤 Setting up service account...${NC}"
SERVICE_ACCOUNT="ruby-rx-service-account"
if ! gcloud iam service-accounts describe ${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com >/dev/null 2>&1; then
    gcloud iam service-accounts create ${SERVICE_ACCOUNT} \
        --display-name="Ruby RX Service Account"
    
    # Grant necessary permissions
    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member="serviceAccount:${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
        --role="roles/cloudsql.client"
    
    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member="serviceAccount:${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
        --role="roles/redis.editor"
    
    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member="serviceAccount:${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
        --role="roles/ml.aiPlatform.user"
    
    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member="serviceAccount:${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
        --role="roles/vision.annotator"
fi

# Create service account key
echo -e "${YELLOW}🔑 Creating service account key...${NC}"
gcloud iam service-accounts keys create ./service-account-key.json \
    --iam-account=${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com

# Create secrets in Secret Manager
echo -e "${YELLOW}🔒 Creating secrets in Secret Manager...${NC}"

# Enable Secret Manager API
gcloud services enable secretmanager.googleapis.com

# Create secrets (you'll need to add actual values)
echo -e "${YELLOW}📝 Please create the following secrets manually in Secret Manager:${NC}"
echo "- db-credentials (username, password, database)"
echo "- medicine-db-credentials (username, password, database)"
echo "- redis-credentials (connection-string)"
echo "- app-secrets (jwt-secret)"
echo "- oauth-credentials (google-client-id, google-client-secret, etc.)"
echo "- email-credentials (gmail-user, gmail-app-password)"
echo "- api-keys (whatsapp-api-key, genai-api-key)"
echo "- gcp-config (project-id)"

# Store service account key as secret
gcloud secrets create gcp-service-account-key \
    --data-file=./service-account-key.json || echo "Secret already exists"

# Deploy to Cloud Run
echo -e "${YELLOW}🚀 Deploying to Cloud Run...${NC}"

# Update the service YAML with actual project ID
sed -i.bak "s/PROJECT_ID/${PROJECT_ID}/g" cloud-run-service.yaml
sed -i.bak "s/REGION/${REGION}/g" cloud-run-service.yaml

# Deploy using gcloud run services replace
gcloud run services replace cloud-run-service.yaml \
    --region=${REGION}

# Allow unauthenticated access (optional, remove if you want authentication)
gcloud run services add-iam-policy-binding ${SERVICE_NAME} \
    --region=${REGION} \
    --member="allUsers" \
    --role="roles/run.invoker"

# Get the service URL
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
    --region=${REGION} \
    --format="value(status.url)")

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo -e "${GREEN}🌐 Service URL: ${SERVICE_URL}${NC}"
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "1. Update your OAuth redirect URIs to use the new service URL"
echo "2. Configure your database schemas by accessing ${SERVICE_URL}/api/health/databases"
echo "3. Set up proper monitoring and logging"
echo "4. Configure domain and SSL if needed"

# Clean up
rm -f ./service-account-key.json
rm -f cloud-run-service.yaml.bak