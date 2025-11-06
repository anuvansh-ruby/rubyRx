#!/bin/bash

# Setup Artifact Registry Repository
set -e

# Configuration Variables
PROJECT_ID="${GCP_PROJECT_ID:-ruby-477016}"
REGION="${GCP_REGION:-us-central1}"
REPO_NAME="ruby-rx-repo"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🏗️  Setting up Artifact Registry Repository${NC}"

# Check if required environment variables are set
if [ "$PROJECT_ID" = "ruby-477016" ]; then
    echo -e "${YELLOW}⚠️  Using default project ID. Set GCP_PROJECT_ID for your project.${NC}"
fi

# Set the project
echo -e "${YELLOW}📋 Setting GCP project to ${PROJECT_ID}...${NC}"
gcloud config set project ${PROJECT_ID}

# Enable Artifact Registry API
echo -e "${YELLOW}🔧 Enabling Artifact Registry API...${NC}"
gcloud services enable artifactregistry.googleapis.com

# Wait for API to be ready
echo -e "${YELLOW}⏳ Waiting for API to be ready...${NC}"
sleep 15

# Create repository if it doesn't exist
echo -e "${YELLOW}📦 Creating Artifact Registry repository...${NC}"
if gcloud artifacts repositories describe ${REPO_NAME} --location=${REGION} >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Repository ${REPO_NAME} already exists${NC}"
else
    echo -e "${YELLOW}Creating new repository...${NC}"
    gcloud artifacts repositories create ${REPO_NAME} \
        --repository-format=docker \
        --location=${REGION} \
        --description="Ruby RX App Docker Repository"
    echo -e "${GREEN}✅ Repository created successfully${NC}"
fi

# Configure Docker authentication
echo -e "${YELLOW}🔐 Configuring Docker authentication...${NC}"
gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet

# Test access
echo -e "${YELLOW}🧪 Testing repository access...${NC}"
if gcloud artifacts repositories list --location=${REGION} --filter="name:${REPO_NAME}" --format="value(name)" | grep -q ${REPO_NAME}; then
    echo -e "${GREEN}✅ Repository setup completed successfully!${NC}"
    echo -e "${GREEN}🌐 Repository URL: ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}${NC}"
else
    echo -e "${RED}❌ Repository setup failed${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Next steps:${NC}"
echo "1. Run ./quick-deploy.sh to deploy your application"
echo "2. Or run gcloud builds submit --config=cloudbuild.yaml"