#!/bin/bash

# Git Setup Script for GitHub Authentication
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 Git Authentication Setup${NC}"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Not in a git repository${NC}"
    exit 1
fi

# Get current remote URL
REMOTE_URL=$(git config --get remote.origin.url)
echo -e "${YELLOW}Current remote URL: ${REMOTE_URL}${NC}"

# Check if it's using HTTPS
if [[ $REMOTE_URL == https://github.com/* ]]; then
    echo -e "${YELLOW}🔄 Converting HTTPS to SSH for better authentication...${NC}"
    
    # Extract owner/repo from HTTPS URL
    REPO_PATH=$(echo $REMOTE_URL | sed 's|https://github.com/||' | sed 's|\.git$||')
    SSH_URL="git@github.com:${REPO_PATH}.git"
    
    echo -e "${YELLOW}New SSH URL: ${SSH_URL}${NC}"
    
    # Update remote URL to SSH
    git remote set-url origin $SSH_URL
    echo -e "${GREEN}✅ Remote URL updated to SSH${NC}"
    
    echo -e "${YELLOW}📋 Make sure you have:${NC}"
    echo "1. SSH key added to your GitHub account"
    echo "2. SSH key added to ssh-agent: ssh-add ~/.ssh/id_rsa"
    echo "3. Test with: ssh -T git@github.com"
else
    echo -e "${YELLOW}📋 For token authentication with HTTPS:${NC}"
    echo "1. Create a Personal Access Token on GitHub"
    echo "2. Use token as password when prompted"
    echo "3. Or set up credential helper: git config --global credential.helper store"
fi

echo -e "${YELLOW}🔍 Testing connection...${NC}"
if git ls-remote origin > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Git authentication working!${NC}"
else
    echo -e "${RED}❌ Git authentication failed${NC}"
    echo -e "${YELLOW}Please check your SSH keys or GitHub token${NC}"
fi