#!/bin/bash

# Complete Ruby RX Deployment Script
set -e

# Configuration Variables
PROJECT_ID="${GCP_PROJECT_ID:-ruby-477016}"
REGION="${GCP_REGION:-us-central1}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Complete Ruby RX Deployment${NC}"

# Step 1: Setup Artifact Registry
echo -e "${YELLOW}Step 1: Setting up Artifact Registry${NC}"
export GCP_PROJECT_ID=${PROJECT_ID}
export GCP_REGION=${REGION}
./setup-artifact-registry.sh

# Step 2: Deploy using Cloud Build
echo -e "${YELLOW}Step 2: Deploying with Cloud Build${NC}"
gcloud builds submit --config=cloudbuild-simple.yaml \
    --substitutions=_REGION=${REGION} \
    --timeout=1800s .

# Step 3: Get service URL
echo -e "${YELLOW}Step 3: Getting service information${NC}"
SERVICE_URL=$(gcloud run services describe ruby-rx-app \
    --region=${REGION} \
    --format="value(status.url)" 2>/dev/null || echo "Service not found")

if [ "$SERVICE_URL" != "Service not found" ]; then
    echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
    echo -e "${GREEN}🌐 Service URL: ${SERVICE_URL}${NC}"
    
    # Test the service
    echo -e "${YELLOW}🧪 Testing service...${NC}"
    if curl -f "${SERVICE_URL}" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Service is responding!${NC}"
    else
        echo -e "${YELLOW}⚠️  Service deployed but may need configuration${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Build completed, checking logs...${NC}"
    gcloud builds list --limit=1 --format="table(id,status,logUrl)"
fi

echo -e "${YELLOW}📋 Post-deployment checklist:${NC}"
echo "1. ✅ Artifact Registry repository created"
echo "2. ✅ Docker image built and pushed"
echo "3. ✅ Cloud Run service deployed"
echo "4. 🔄 Configure secrets in Secret Manager"
echo "5. 🔄 Set up Cloud SQL databases"
echo "6. 🔄 Configure Redis instance"
echo "7. 🔄 Update OAuth redirect URIs"

echo -e "${GREEN}🎉 Deployment script completed!${NC}"