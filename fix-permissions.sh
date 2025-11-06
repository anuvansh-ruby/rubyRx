#!/bin/bash

# Fix Cloud Build and Artifact Registry Permissions
set -e

# Configuration Variables
PROJECT_ID="ruby-477016"
PROJECT_NUMBER="235422546541"
REGION="us-central1"
REPO_NAME="ruby-rx-repo"
USER_EMAIL="adityaraj61522@gmail.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 Fixing Cloud Build and Artifact Registry Permissions${NC}"

echo -e "${YELLOW}Step 1: Granting permissions to your user account...${NC}"
# Grant your user account the necessary permissions
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="user:${USER_EMAIL}" \
    --role="roles/serviceusage.serviceUsageAdmin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="user:${USER_EMAIL}" \
    --role="roles/artifactregistry.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="user:${USER_EMAIL}" \
    --role="roles/run.admin"

echo -e "${YELLOW}Step 2: Granting permissions to Cloud Build service account...${NC}"
# Grant Cloud Build service account the necessary permissions
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
    --role="roles/artifactregistry.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
    --role="roles/serviceusage.serviceUsageAdmin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
    --role="roles/run.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
    --role="roles/storage.admin"

echo -e "${YELLOW}Step 3: Enabling required APIs...${NC}"
gcloud services enable artifactregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com

echo -e "${YELLOW}Step 4: Creating Artifact Registry repository...${NC}"
# Wait for API to be ready
sleep 10

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

echo -e "${YELLOW}Step 5: Configuring Docker authentication...${NC}"
gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet

echo -e "${GREEN}✅ All permissions and setup completed successfully!${NC}"
echo -e "${GREEN}🌐 Repository URL: ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}${NC}"