#!/bin/bash

#############################################
# Angular AWS S3 Deployment Script
# Usage: ./deploy.sh [dev|qa|staging|prod]
#############################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get environment from first parameter
ENVIRONMENT=$1

# Load UNIQUE_ID from .env.aws file
if [ ! -f .env.aws ]; then
  echo -e "${RED}Error: .env.aws file not found!${NC}"
  echo "Please ensure .env.aws exists with UNIQUE_ID variable"
  exit 1
fi

source .env.aws

# Validate environment parameter
if [ -z "$ENVIRONMENT" ]; then
  echo -e "${RED}Error: No environment specified${NC}"
  echo ""
  echo "Usage: ./deploy.sh [dev|qa|staging|prod]"
  echo ""
  echo "Examples:"
  echo "  ./deploy.sh dev       # Deploy to development"
  echo "  ./deploy.sh qa        # Deploy to QA"
  echo "  ./deploy.sh staging   # Deploy to staging"
  echo "  ./deploy.sh prod      # Deploy to production"
  exit 1
fi

# Validate environment is one of the allowed values
case $ENVIRONMENT in
  dev|qa|staging|prod)
    # Valid environment
    ;;
  *)
    echo -e "${RED}Error: Invalid environment '${ENVIRONMENT}'${NC}"
    echo "Must be one of: dev, qa, staging, prod"
    exit 1
    ;;
esac

# Set bucket name based on environment
BUCKET_NAME="angular-deploy-${ENVIRONMENT}-${UNIQUE_ID}"

# Set configuration file mapping
# Map 'prod' to 'production' for the config file
if [ "$ENVIRONMENT" = "prod" ]; then
  CONFIG_FILE="environment.production.json"
else
  CONFIG_FILE="environment.${ENVIRONMENT}.json"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  AWS S3 Deployment Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Environment:  ${ENVIRONMENT}"
echo "Bucket:       ${BUCKET_NAME}"
echo "Config:       ${CONFIG_FILE}"
echo ""

# Step 1: Build Angular app
echo -e "${YELLOW}[1/4] Building Angular application...${NC}"
npm run build -- --configuration=production

if [ $? -ne 0 ]; then
  echo -e "${RED}Build failed! Aborting deployment.${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Build completed successfully${NC}"
echo ""

# Step 2: Swap environment configuration
echo -e "${YELLOW}[2/4] Swapping environment configuration...${NC}"

SOURCE_CONFIG="src/assets/config/${CONFIG_FILE}"
TARGET_CONFIG="dist/angular-release-deployment-frontend/browser/assets/config/environment.json"

if [ ! -f "$SOURCE_CONFIG" ]; then
  echo -e "${RED}Error: Config file not found: ${SOURCE_CONFIG}${NC}"
  exit 1
fi

cp "$SOURCE_CONFIG" "$TARGET_CONFIG"
echo -e "${GREEN}✅ Configuration swapped to ${ENVIRONMENT}${NC}"
echo ""

# Step 3: Deploy to S3
echo -e "${YELLOW}[3/4] Deploying to S3 bucket: ${BUCKET_NAME}${NC}"
echo ""

aws s3 sync dist/angular-release-deployment-frontend/browser \
  s3://${BUCKET_NAME} --delete

if [ $? -ne 0 ]; then
  echo -e "${RED}Deployment failed!${NC}"
  exit 1
fi

echo ""
echo -e "${GREEN}✅ Files uploaded to S3${NC}"
echo ""

# Step 4: Invalidate CloudFront cache (production only)
if [ "$ENVIRONMENT" = "prod" ]; then
  echo -e "${YELLOW}[4/5] Invalidating CloudFront cache...${NC}"
  echo ""

  if [ -z "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
    echo -e "${YELLOW}⚠️  CloudFront distribution ID not found in .env.aws${NC}"
    echo -e "${YELLOW}⚠️  Skipping cache invalidation${NC}"
    echo ""
  else
    aws cloudfront create-invalidation \
      --distribution-id ${CLOUDFRONT_DISTRIBUTION_ID} \
      --paths "/*" > /dev/null

    if [ $? -eq 0 ]; then
      echo -e "${GREEN}✅ CloudFront cache invalidated${NC}"
      echo -e "${GREEN}   Fresh content will be available within 1-2 minutes${NC}"
    else
      echo -e "${YELLOW}⚠️  CloudFront invalidation failed (not critical)${NC}"
    fi
    echo ""
  fi
fi

# Step 5: Show website URLs
if [ "$ENVIRONMENT" = "prod" ]; then
  echo -e "${YELLOW}[5/5] Deployment complete!${NC}"
else
  echo -e "${YELLOW}[4/4] Deployment complete!${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Deployment Successful! 🚀${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Environment:  ${ENVIRONMENT}"
echo "Bucket:       ${BUCKET_NAME}"
echo ""

if [ "$ENVIRONMENT" = "prod" ]; then
  echo -e "Your app is live at:"
  echo -e "${GREEN}https://${CLOUDFRONT_DOMAIN}${NC} ${YELLOW}(CloudFront - Recommended)${NC}"
  echo -e "http://${BUCKET_NAME}.s3-website-us-east-1.amazonaws.com ${YELLOW}(S3 Direct)${NC}"
else
  echo -e "Your app is live at:"
  echo -e "${GREEN}http://${BUCKET_NAME}.s3-website-us-east-1.amazonaws.com${NC}"
fi

echo ""
