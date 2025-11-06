#!/bin/bash

# Fix deployment permissions for Ruby RX App
set -e

# Configuration Variables
PROJECT_ID="ruby-477016"
SERVICE_ACCOUNT="ruby-rx-service-account"
CLOUD_BUILD_SERVICE_ACCOUNT="235422546541-compute@developer.gserviceaccount.com"

echo "🔧 Fixing Cloud Build deployment permissions..."

# Grant Cloud Build service account permission to act as the custom service account
echo "1. Granting Service Account Token Creator role to Cloud Build service account..."
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${CLOUD_BUILD_SERVICE_ACCOUNT}" \
    --role="roles/iam.serviceAccountTokenCreator"

# Grant Cloud Build service account permission to use the custom service account
echo "2. Granting Service Account User role to Cloud Build service account..."
gcloud iam service-accounts add-iam-policy-binding \
    ${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com \
    --member="serviceAccount:${CLOUD_BUILD_SERVICE_ACCOUNT}" \
    --role="roles/iam.serviceAccountUser"

# Grant Cloud Build service account Cloud Run Admin role
echo "3. Granting Cloud Run Admin role to Cloud Build service account..."
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${CLOUD_BUILD_SERVICE_ACCOUNT}" \
    --role="roles/run.admin"

# Grant Cloud Build service account Storage Admin role for Artifact Registry
echo "4. Granting Storage Admin role to Cloud Build service account..."
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${CLOUD_BUILD_SERVICE_ACCOUNT}" \
    --role="roles/storage.admin"

# Grant Cloud Build service account Artifact Registry Admin role
echo "5. Granting Artifact Registry Admin role to Cloud Build service account..."
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${CLOUD_BUILD_SERVICE_ACCOUNT}" \
    --role="roles/artifactregistry.admin"

echo "✅ Permissions fixed! You can now retry the deployment."
echo ""
echo "To retry deployment, run:"
echo "gcloud builds submit --config=cloudbuild.yaml --substitutions=_REGION=us-central1 --timeout=1800s ."