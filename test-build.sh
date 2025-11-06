#!/bin/bash

# Local Docker Build Test Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🧪 Local Docker Build Test${NC}"

# Configuration
PROJECT_ID="${GCP_PROJECT_ID:-ruby-477016}"
REGION="${GCP_REGION:-us-central1}"
IMAGE_NAME="${REGION}-docker.pkg.dev/${PROJECT_ID}/ruby-rx-repo/ruby-rx-app"

echo -e "${YELLOW}📋 Using Project ID: ${PROJECT_ID}${NC}"

# Build the Docker image locally
echo -e "${YELLOW}🏗️  Building Docker image locally...${NC}"
docker build -t ${IMAGE_NAME}:local-test .

# Test the image locally
echo -e "${YELLOW}🧪 Testing the image locally...${NC}"
echo -e "${YELLOW}Starting container on port 8080...${NC}"

# Stop any existing container
docker stop ruby-rx-test 2>/dev/null || true
docker rm ruby-rx-test 2>/dev/null || true

# Run the container
docker run -d \
  --name ruby-rx-test \
  -p 8080:8080 \
  -e NODE_ENV=development \
  -e PORT=8080 \
  -e DB_HOST=host.docker.internal \
  -e DB_USER=test \
  -e DB_PASSWORD=test \
  -e DB_NAME=test \
  -e REDIS_URL=redis://host.docker.internal:6379 \
  -e JWT_SECRET=test-secret \
  ${IMAGE_NAME}:local-test

echo -e "${YELLOW}⏳ Waiting for container to start...${NC}"
sleep 5

# Test the health endpoint
echo -e "${YELLOW}🩺 Testing health endpoint...${NC}"
if curl -f http://localhost:8080/api/health/databases 2>/dev/null; then
    echo -e "${GREEN}✅ Health endpoint responded successfully!${NC}"
else
    echo -e "${YELLOW}⚠️  Health endpoint not responding (expected without database)${NC}"
fi

# Show container logs
echo -e "${YELLOW}📋 Container logs:${NC}"
docker logs ruby-rx-test --tail 20

echo -e "${GREEN}✅ Local build test completed!${NC}"
echo -e "${YELLOW}🧹 To cleanup, run: docker stop ruby-rx-test && docker rm ruby-rx-test${NC}"
echo -e "${YELLOW}🚀 If everything looks good, run: ./quick-deploy.sh${NC}"