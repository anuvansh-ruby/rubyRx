#!/bin/bash

# Quick script to create all required secrets
# Replace the placeholder values with your actual values

PROJECT_ID="ruby-477016"

# Database credentials - REPLACE THESE VALUES
echo -n "your_main_db_username" | gcloud secrets create db-credentials--username --data-file=- --replication-policy=automatic --project=$PROJECT_ID
echo -n "your_main_db_password" | gcloud secrets create db-credentials--password --data-file=- --replication-policy=automatic --project=$PROJECT_ID
echo -n "your_main_db_name" | gcloud secrets create db-credentials--database --data-file=- --replication-policy=automatic --project=$PROJECT_ID

# Medicine database credentials - REPLACE THESE VALUES
echo -n "your_medicine_db_username" | gcloud secrets create medicine-db-credentials--username --data-file=- --replication-policy=automatic --project=$PROJECT_ID
echo -n "your_medicine_db_password" | gcloud secrets create medicine-db-credentials--password --data-file=- --replication-policy=automatic --project=$PROJECT_ID
echo -n "your_medicine_db_name" | gcloud secrets create medicine-db-credentials--database --data-file=- --replication-policy=automatic --project=$PROJECT_ID

# Redis - REPLACE THIS VALUE
echo -n "your_redis_connection_string" | gcloud secrets create redis-credentials--connection-string --data-file=- --replication-policy=automatic --project=$PROJECT_ID

# JWT Secret - REPLACE THIS VALUE (generate a strong random string)
echo -n "your_jwt_secret_key_here" | gcloud secrets create app-secrets--jwt-secret --data-file=- --replication-policy=automatic --project=$PROJECT_ID

# Google OAuth - REPLACE THESE VALUES
echo -n "your_google_client_id" | gcloud secrets create oauth-credentials--google-client-id --data-file=- --replication-policy=automatic --project=$PROJECT_ID
echo -n "your_google_client_secret" | gcloud secrets create oauth-credentials--google-client-secret --data-file=- --replication-policy=automatic --project=$PROJECT_ID
echo -n "your_google_redirect_uri" | gcloud secrets create oauth-credentials--google-redirect-uri --data-file=- --replication-policy=automatic --project=$PROJECT_ID

# LinkedIn OAuth - REPLACE THESE VALUES
echo -n "your_linkedin_client_id" | gcloud secrets create oauth-credentials--linkedin-client-id --data-file=- --replication-policy=automatic --project=$PROJECT_ID
echo -n "your_linkedin_client_secret" | gcloud secrets create oauth-credentials--linkedin-client-secret --data-file=- --replication-policy=automatic --project=$PROJECT_ID
echo -n "your_linkedin_redirect_uri" | gcloud secrets create oauth-credentials--linkedin-redirect-uri --data-file=- --replication-policy=automatic --project=$PROJECT_ID

# Email credentials - REPLACE THESE VALUES
echo -n "your_gmail_address" | gcloud secrets create email-credentials--gmail-user --data-file=- --replication-policy=automatic --project=$PROJECT_ID
echo -n "your_gmail_app_password" | gcloud secrets create email-credentials--gmail-app-password --data-file=- --replication-policy=automatic --project=$PROJECT_ID

# API Keys - REPLACE THESE VALUES (or use empty string if not needed yet)
echo -n "your_whatsapp_api_key" | gcloud secrets create api-keys--whatsapp-api-key --data-file=- --replication-policy=automatic --project=$PROJECT_ID
echo -n "your_genai_api_key" | gcloud secrets create api-keys--genai-api-key --data-file=- --replication-policy=automatic --project=$PROJECT_ID

# GCP Config
echo -n "ruby-477016" | gcloud secrets create gcp-config--project-id --data-file=- --replication-policy=automatic --project=$PROJECT_ID

# Grant access to Cloud Run service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:235422546541-compute@developer.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"

echo ""
echo "✓ All secrets created!"
echo "Run: gcloud secrets list --project=$PROJECT_ID"
