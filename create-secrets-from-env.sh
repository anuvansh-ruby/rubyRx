#!/bin/bash

# This script creates GCP secrets from your local .env file
# Usage: ./create-secrets-from-env.sh /path/to/.env

set -e

PROJECT_ID="ruby-477016"
ENV_FILE="${1:-b_ruby_rx_app/.env}"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at: $ENV_FILE"
    echo "Usage: $0 /path/to/.env"
    echo ""
    echo "Please create a .env file with your actual values first!"
    echo "You can use b_ruby_rx_app/.env.example as a template"
    exit 1
fi

echo "Reading environment variables from: $ENV_FILE"
echo "Creating secrets in project: $PROJECT_ID"
echo ""

# Load the .env file
source "$ENV_FILE"

# Function to create secret
create_secret() {
    local secret_name=$1
    local secret_value=$2
    
    if [ -z "$secret_value" ]; then
        echo "⚠ Skipping $secret_name (empty value)"
        return
    fi
    
    echo "Creating secret: $secret_name"
    echo -n "$secret_value" | gcloud secrets create "$secret_name" \
        --data-file=- \
        --replication-policy=automatic \
        --project=$PROJECT_ID 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✓ Created $secret_name"
    else
        echo "✗ Failed to create $secret_name (may already exist)"
    fi
}

echo "=== Creating Database Secrets ==="
create_secret "db-credentials--username" "$DB_USER"
create_secret "db-credentials--password" "$DB_PASSWORD"
create_secret "db-credentials--database" "$DB_NAME"

echo ""
echo "=== Creating Medicine Database Secrets ==="
create_secret "medicine-db-credentials--username" "$MEDICINE_DB_USER"
create_secret "medicine-db-credentials--password" "$MEDICINE_DB_PASSWORD"
create_secret "medicine-db-credentials--database" "$MEDICINE_DB_NAME"

echo ""
echo "=== Creating Redis Secrets ==="
# Build Redis connection string from components
REDIS_CONNECTION_STRING="redis://${REDIS_HOST}:${REDIS_PORT}"
if [ -n "$REDIS_PASSWORD" ] && [ "$REDIS_PASSWORD" != "''" ]; then
    REDIS_CONNECTION_STRING="redis://:${REDIS_PASSWORD}@${REDIS_HOST}:${REDIS_PORT}"
fi
create_secret "redis-credentials--connection-string" "$REDIS_CONNECTION_STRING"

echo ""
echo "=== Creating App Secrets ==="
create_secret "app-secrets--jwt-secret" "$JWT_SECRET"

echo ""
echo "=== Creating Google OAuth Secrets ==="
create_secret "oauth-credentials--google-client-id" "$GOOGLE_CLIENT_ID"
create_secret "oauth-credentials--google-client-secret" "$GOOGLE_CLIENT_SECRET"
create_secret "oauth-credentials--google-redirect-uri" "$GOOGLE_REDIRECT_URI"

echo ""
echo "=== Creating LinkedIn OAuth Secrets ==="
create_secret "oauth-credentials--linkedin-client-id" "$LINKEDIN_CLIENT_ID"
create_secret "oauth-credentials--linkedin-client-secret" "$LINKEDIN_CLIENT_SECRET"
create_secret "oauth-credentials--linkedin-redirect-uri" "$LINKEDIN_REDIRECT_URI"

echo ""
echo "=== Creating Email Secrets ==="
create_secret "email-credentials--gmail-user" "$GOOGLE_EMAIL_USER"
create_secret "email-credentials--gmail-app-password" "$GOOGLE_APP_PASSWORD"

echo ""
echo "=== Creating API Key Secrets ==="
create_secret "api-keys--whatsapp-api-key" "$WASENDER_API_KEY"
create_secret "api-keys--genai-api-key" "$GEMINI_API_KEY"

echo ""
echo "=== Creating GCP Config Secrets ==="
create_secret "gcp-config--project-id" "$PROJECT_ID"

echo ""
echo "=== Granting Secret Manager Access ==="
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:235422546541-compute@developer.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"

echo ""
echo "✓ All secrets created successfully!"
echo ""
echo "Verify with: gcloud secrets list --project=$PROJECT_ID"
