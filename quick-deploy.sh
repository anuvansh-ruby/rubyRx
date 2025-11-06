#!/bin/bash

# Quick Cloud Build Deployment Script for Ruby RX App
set -e

# Configuration Variables
PROJECT_ID="${GCP_PROJECT_ID:-your-gcp-project-id}"
REGION="${GCP_REGION:-us-central1}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Quick Cloud Build Deployment${NC}"

# Check if required environment variables are set
if [ "$PROJECT_ID" = "your-gcp-project-id" ]; then
    echo -e "${RED}❌ Please set GCP_PROJECT_ID environment variable${NC}"
    echo -e "${YELLOW}Example: export GCP_PROJECT_ID=my-project-id${NC}"
    exit 1
fi

# Set the project
echo -e "${YELLOW}📋 Setting GCP project to ${PROJECT_ID}...${NC}"
gcloud config set project ${PROJECT_ID}

# Check authentication
echo -e "${YELLOW}🔐 Checking GCP authentication...${NC}"
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo -e "${YELLOW}Please authenticate with GCP:${NC}"
    gcloud auth login
fi

# Enable required APIs
echo -e "${YELLOW}🔧 Enabling required APIs...${NC}"
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable artifactregistry.googleapis.com

# Submit build
echo -e "${YELLOW}🏗️  Submitting build to Cloud Build...${NC}"
gcloud builds submit --config=cloudbuild.yaml \
    --substitutions=_REGION=${REGION} \
    --timeout=1800s .

# Get the service URL
echo -e "${YELLOW}🔍 Getting service URL...${NC}"
SERVICE_URL=$(gcloud run services describe ruby-rx-app \
    --region=${REGION} \
    --format="value(status.url)" 2>/dev/null || echo "Service not found")

if [ "$SERVICE_URL" != "Service not found" ]; then
    echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
    echo -e "${GREEN}🌐 Service URL: ${SERVICE_URL}${NC}"
else
    echo -e "${YELLOW}⚠️  Build completed, but service URL not available yet${NC}"
    echo -e "${YELLOW}Check Cloud Run console: https://console.cloud.google.com/run?project=${PROJECT_ID}${NC}"
fi

echo -e "${YELLOW}📋 Next steps:${NC}"
echo "1. Configure your secrets in Secret Manager"
echo "2. Set up Cloud SQL databases and Redis"
echo "3. Update OAuth redirect URIs"
echo "4. Test the health endpoint: \${SERVICE_URL}/api/health/databases"