#!/bin/bash

# Manual deployment script for Ruby RX App
set -e

PROJECT_ID="ruby-477016"
REGION="us-central1"
SERVICE_NAME="ruby-rx-app"
IMAGE_TAG="manual-$(date +%Y%m%d-%H%M%S)"

echo "🚀 Starting manual deployment..."

# Check if we can access the project
echo "📋 Checking project access..."
if ! gcloud projects describe ${PROJECT_ID} >/dev/null 2>&1; then
    echo "❌ Cannot access project ${PROJECT_ID}. Please check permissions."
    exit 1
fi

# Set up Docker authentication for Artifact Registry
echo "🔐 Setting up Docker authentication..."
if ! gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet; then
    echo "❌ Failed to configure Docker authentication."
    exit 1
fi

# Build Docker image locally
echo "🏗️  Building Docker image locally..."
docker build -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/ruby-rx-repo/ruby-rx-app:${IMAGE_TAG} .

# Push the image
echo "📤 Pushing image to Artifact Registry..."
if ! docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/ruby-rx-repo/ruby-rx-app:${IMAGE_TAG}; then
    echo "❌ Failed to push image. Checking if repository exists..."
    
    # Try to create repository if it doesn't exist
    echo "🏗️  Attempting to create Artifact Registry repository..."
    gcloud artifacts repositories create ruby-rx-repo \
        --repository-format=docker \
        --location=${REGION} \
        --description="Ruby RX App Docker Repository" || echo "Repository might already exist"
    
    # Retry push
    echo "🔄 Retrying push..."
    docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/ruby-rx-repo/ruby-rx-app:${IMAGE_TAG}
fi

# Deploy to Cloud Run
echo "🚀 Deploying to Cloud Run..."
gcloud run deploy ${SERVICE_NAME} \
    --image=${REGION}-docker.pkg.dev/${PROJECT_ID}/ruby-rx-repo/ruby-rx-app:${IMAGE_TAG} \
    --region=${REGION} \
    --platform=managed \
    --allow-unauthenticated \
    --memory=2Gi \
    --cpu=2 \
    --max-instances=10 \
    --min-instances=1 \
    --port=8080 \
    --timeout=300 \
    --concurrency=1000 \
    --set-env-vars="NODE_ENV=production,PORT=8080"

# Get service URL
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
    --region=${REGION} \
    --format="value(status.url)" 2>/dev/null || echo "Could not retrieve URL")

echo "✅ Manual deployment completed!"
echo "🌐 Service URL: ${SERVICE_URL}"
echo "📋 Image used: ${REGION}-docker.pkg.dev/${PROJECT_ID}/ruby-rx-repo/ruby-rx-app:${IMAGE_TAG}"