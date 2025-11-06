#!/bin/bash

# Script to create all required secrets in Google Secret Manager
# Each secret is created individually as GCP Secret Manager stores each key as a separate secret

PROJECT_ID="ruby-477016"

echo "Creating secrets for Ruby RX application..."
echo "Note: For passwords, input will be hidden."
echo ""

# Function to create secret
create_secret() {
    local secret_name=$1
    local secret_value=$2
    
    echo "Creating secret: $secret_name"
    echo -n "$secret_value" | gcloud secrets create "$secret_name" \
        --data-file=- \
        --replication-policy=automatic \
        --project=$PROJECT_ID 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✓ Created $secret_name"
    else
        echo "✗ Failed to create $secret_name (may already exist)"
    fi
}

# Main Database Credentials
echo ""
echo "=== Main Database Credentials ==="
read -p "Enter MAIN_DB_USER: " MAIN_DB_USER
create_secret "db-credentials--username" "$MAIN_DB_USER"

read -sp "Enter MAIN_DB_PASSWORD: " MAIN_DB_PASSWORD
echo ""
create_secret "db-credentials--password" "$MAIN_DB_PASSWORD"

read -p "Enter MAIN_DB_NAME: " MAIN_DB_NAME
create_secret "db-credentials--database" "$MAIN_DB_NAME"

# Medicine Database Credentials
echo ""
echo "=== Medicine Database Credentials ==="
read -p "Enter MEDICINE_DB_USER: " MEDICINE_DB_USER
create_secret "medicine-db-credentials--username" "$MEDICINE_DB_USER"

read -sp "Enter MEDICINE_DB_PASSWORD: " MEDICINE_DB_PASSWORD
echo ""
create_secret "medicine-db-credentials--password" "$MEDICINE_DB_PASSWORD"

read -p "Enter MEDICINE_DB_NAME: " MEDICINE_DB_NAME
create_secret "medicine-db-credentials--database" "$MEDICINE_DB_NAME"

# Redis Credentials
echo ""
echo "=== Redis Credentials ==="
read -p "Enter REDIS_CONNECTION_STRING: " REDIS_CONNECTION_STRING
create_secret "redis-credentials--connection-string" "$REDIS_CONNECTION_STRING"

# Application Secrets
echo ""
echo "=== Application Secrets ==="
read -p "Enter JWT_SECRET_KEY: " JWT_SECRET_KEY
create_secret "app-secrets--jwt-secret" "$JWT_SECRET_KEY"

# OAuth Credentials - Google
echo ""
echo "=== OAuth Credentials - Google ==="
read -p "Enter GOOGLE_OAUTH_CLIENT_ID: " GOOGLE_OAUTH_CLIENT_ID
create_secret "oauth-credentials--google-client-id" "$GOOGLE_OAUTH_CLIENT_ID"

read -p "Enter GOOGLE_OAUTH_CLIENT_SECRET: " GOOGLE_OAUTH_CLIENT_SECRET
create_secret "oauth-credentials--google-client-secret" "$GOOGLE_OAUTH_CLIENT_SECRET"

read -p "Enter GOOGLE_OAUTH_REDIRECT_URI: " GOOGLE_OAUTH_REDIRECT_URI
create_secret "oauth-credentials--google-redirect-uri" "$GOOGLE_OAUTH_REDIRECT_URI"

# OAuth Credentials - LinkedIn
echo ""
echo "=== OAuth Credentials - LinkedIn ==="
read -p "Enter LINKEDIN_OAUTH_CLIENT_ID: " LINKEDIN_OAUTH_CLIENT_ID
create_secret "oauth-credentials--linkedin-client-id" "$LINKEDIN_OAUTH_CLIENT_ID"

read -p "Enter LINKEDIN_OAUTH_CLIENT_SECRET: " LINKEDIN_OAUTH_CLIENT_SECRET
create_secret "oauth-credentials--linkedin-client-secret" "$LINKEDIN_OAUTH_CLIENT_SECRET"

read -p "Enter LINKEDIN_OAUTH_REDIRECT_URI: " LINKEDIN_OAUTH_REDIRECT_URI
create_secret "oauth-credentials--linkedin-redirect-uri" "$LINKEDIN_OAUTH_REDIRECT_URI"

# Email Credentials
echo ""
echo "=== Email Credentials ==="
read -p "Enter GMAIL_USER: " GMAIL_USER
create_secret "email-credentials--gmail-user" "$GMAIL_USER"

read -sp "Enter GMAIL_APP_PASSWORD: " GMAIL_APP_PASSWORD
echo ""
create_secret "email-credentials--gmail-app-password" "$GMAIL_APP_PASSWORD"

# API Keys
echo ""
echo "=== API Keys ==="
read -p "Enter WHATSAPP_API_KEY (or press Enter to skip): " WHATSAPP_API_KEY
if [ -n "$WHATSAPP_API_KEY" ]; then
    create_secret "api-keys--whatsapp-api-key" "$WHATSAPP_API_KEY"
fi

read -p "Enter GENAI_API_KEY (or press Enter to skip): " GENAI_API_KEY
if [ -n "$GENAI_API_KEY" ]; then
    create_secret "api-keys--genai-api-key" "$GENAI_API_KEY"
fi

# GCP Config
echo ""
echo "=== GCP Config ==="
create_secret "gcp-config--project-id" "$PROJECT_ID"

echo ""
echo "✓ All secrets creation attempted!"
echo ""
echo "Now granting Secret Manager access to Cloud Run service account..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:235422546541-compute@developer.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"

echo ""
echo "✓ Setup complete! You can now deploy your Cloud Run service."
