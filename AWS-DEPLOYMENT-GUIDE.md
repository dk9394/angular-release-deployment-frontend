# AWS Deployment Setup Guide

## Phase 4A: Frontend AWS Deployment

### Prerequisites
- AWS Account (create at https://aws.amazon.com if you don't have one)
- AWS CLI installed
- Credit card for AWS (free tier available)

---

## Step 1: AWS Account Setup

1. Go to https://aws.amazon.com
2. Click "Create an AWS Account"
3. Follow the signup process
4. Choose "Free tier" (sufficient for learning)
5. Verify email and phone

**Note**: AWS requires credit card but won't charge for free tier usage

---

## Step 2: Install AWS CLI

```bash
# macOS
brew install awscli

# Verify installation
aws --version

# Configure AWS CLI
aws configure
# Enter:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region: us-east-1
# - Default output format: json
```

**Getting Access Keys:**
1. AWS Console → IAM → Users → Your user
2. Security credentials → Create access key
3. Download and save securely

---

## Step 3: Create S3 Buckets (4 Environments)

### Bucket Naming Convention
```
angular-deploy-dev-[your-unique-id]
angular-deploy-qa-[your-unique-id]
angular-deploy-staging-[your-unique-id]
angular-deploy-prod-[your-unique-id]
```

### Create Buckets via AWS CLI

```bash
# Set your unique ID (use your name or random string)
UNIQUE_ID="your-name-123"

# Create development bucket
aws s3 mb s3://angular-deploy-dev-${UNIQUE_ID} --region us-east-1

# Create QA bucket
aws s3 mb s3://angular-deploy-qa-${UNIQUE_ID} --region us-east-1

# Create staging bucket
aws s3 mb s3://angular-deploy-staging-${UNIQUE_ID} --region us-east-1

# Create production bucket
aws s3 mb s3://angular-deploy-prod-${UNIQUE_ID} --region us-east-1

# List buckets to verify
aws s3 ls
```

---

## Step 4: Configure S3 for Static Website Hosting

### Enable Website Hosting for Each Bucket

```bash
# Development
aws s3 website s3://angular-deploy-dev-${UNIQUE_ID} \
  --index-document index.html \
  --error-document index.html

# QA
aws s3 website s3://angular-deploy-qa-${UNIQUE_ID} \
  --index-document index.html \
  --error-document index.html

# Staging
aws s3 website s3://angular-deploy-staging-${UNIQUE_ID} \
  --index-document index.html \
  --error-document index.html

# Production
aws s3 website s3://angular-deploy-prod-${UNIQUE_ID} \
  --index-document index.html \
  --error-document index.html
```

**Why `index.html` for error document?**
- Angular is a SPA (Single Page Application)
- All routes handled by Angular Router
- 404 errors should serve index.html, Angular handles routing

---

## Step 5: Set Bucket Policies (Public Read Access)

Create file: `bucket-policy.json`

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::BUCKET_NAME/*"
    }
  ]
}
```

Apply policy to each bucket:

```bash
# Development
cat > dev-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::angular-deploy-dev-${UNIQUE_ID}/*"
    }
  ]
}
EOF

aws s3api put-bucket-policy \
  --bucket angular-deploy-dev-${UNIQUE_ID} \
  --policy file://dev-policy.json

# Repeat for QA, Staging, Production
# (Replace bucket name in policy JSON)
```

---

## Step 6: Build and Deploy Angular App

### Build for Each Environment

```bash
# Development build
npm run build -- --configuration=development

# Production build
npm run build -- --configuration=production
```

### Deploy to S3

```bash
# Deploy to development
aws s3 sync dist/angular-release-deployment-frontend/browser \
  s3://angular-deploy-dev-${UNIQUE_ID} --delete

# Deploy to production
aws s3 sync dist/angular-release-deployment-frontend/browser \
  s3://angular-deploy-prod-${UNIQUE_ID} --delete
```

**Flags:**
- `sync`: Uploads only changed files
- `--delete`: Removes files in S3 that don't exist locally

---

## Step 7: Get Website URLs

```bash
# Development URL
echo "http://angular-deploy-dev-${UNIQUE_ID}.s3-website-us-east-1.amazonaws.com"

# QA URL
echo "http://angular-deploy-qa-${UNIQUE_ID}.s3-website-us-east-1.amazonaws.com"

# Staging URL
echo "http://angular-deploy-staging-${UNIQUE_ID}.s3-website-us-east-1.amazonaws.com"

# Production URL
echo "http://angular-deploy-prod-${UNIQUE_ID}.s3-website-us-east-1.amazonaws.com"
```

---

## Step 8: Set Up CloudFront (CDN) for Production

### Why CloudFront?
- Global CDN (faster loading worldwide)
- HTTPS support
- Caching
- DDoS protection
- Custom domain support

### Create CloudFront Distribution

```bash
# Via AWS Console (easier for first time)
1. AWS Console → CloudFront → Create Distribution
2. Origin domain: Select your S3 bucket
3. Viewer protocol policy: Redirect HTTP to HTTPS
4. Allowed HTTP methods: GET, HEAD, OPTIONS
5. Cache policy: CachingOptimized
6. Price class: Use all edge locations
7. Create distribution

# Note the CloudFront domain (e.g., d123abc.cloudfront.net)
```

### CloudFront Configuration for SPA

**Important**: Configure error pages for Angular routing

1. CloudFront → Your distribution → Error Pages
2. Create custom error response:
   - HTTP error code: 403
   - Customize error response: Yes
   - Response page path: /index.html
   - HTTP response code: 200
3. Repeat for 404 error

---

## Step 9: Deployment Script

Create: `deploy.sh`

```bash
#!/bin/bash

# Deployment script for Angular app
ENVIRONMENT=$1
UNIQUE_ID="your-name-123"

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: ./deploy.sh [dev|qa|staging|prod]"
  exit 1
fi

# Set bucket name based on environment
BUCKET_NAME="angular-deploy-${ENVIRONMENT}-${UNIQUE_ID}"

echo "Building for $ENVIRONMENT..."
npm run build -- --configuration=$ENVIRONMENT

echo "Deploying to S3 bucket: $BUCKET_NAME..."
aws s3 sync dist/angular-release-deployment-frontend/browser \
  s3://$BUCKET_NAME --delete

echo "Deployment complete!"
echo "URL: http://$BUCKET_NAME.s3-website-us-east-1.amazonaws.com"

# If production, invalidate CloudFront cache
if [ "$ENVIRONMENT" = "prod" ]; then
  echo "Invalidating CloudFront cache..."
  aws cloudfront create-invalidation \
    --distribution-id YOUR_DISTRIBUTION_ID \
    --paths "/*"
fi
```

Make executable:
```bash
chmod +x deploy.sh
```

Usage:
```bash
./deploy.sh dev      # Deploy to development
./deploy.sh qa       # Deploy to QA
./deploy.sh staging  # Deploy to staging
./deploy.sh prod     # Deploy to production
```

---

## Step 10: Environment Configuration Swap

### Replace environment.json During Deployment

Update `deploy.sh`:

```bash
#!/bin/bash

ENVIRONMENT=$1
UNIQUE_ID="your-name-123"
BUCKET_NAME="angular-deploy-${ENVIRONMENT}-${UNIQUE_ID}"

# Build for production (same build for all environments)
echo "Building..."
npm run build -- --configuration=production

# Replace environment.json with environment-specific file
echo "Swapping environment config for $ENVIRONMENT..."
cp src/assets/config/environment.${ENVIRONMENT}.json \
   dist/angular-release-deployment-frontend/browser/assets/config/environment.json

# Deploy
echo "Deploying to $BUCKET_NAME..."
aws s3 sync dist/angular-release-deployment-frontend/browser \
  s3://$BUCKET_NAME --delete

echo "Deployment complete!"
```

---

## Step 11: Verify Deployment

### Test Each Environment

```bash
# Open in browser
open http://angular-deploy-dev-${UNIQUE_ID}.s3-website-us-east-1.amazonaws.com
open http://angular-deploy-qa-${UNIQUE_ID}.s3-website-us-east-1.amazonaws.com
open http://angular-deploy-staging-${UNIQUE_ID}.s3-website-us-east-1.amazonaws.com
open http://angular-deploy-prod-${UNIQUE_ID}.s3-website-us-east-1.amazonaws.com

# Or with CloudFront (production)
open https://d123abc.cloudfront.net
```

### Check Environment Config is Loaded

Open browser console and verify:
- Development shows: `apiUrl: "http://localhost:3000/api"`
- Production shows: `apiUrl: "https://api.yourapp.com/api"`

---

## Cost Estimation

### AWS Free Tier (First 12 Months)
- S3: 5GB storage, 20,000 GET requests, 2,000 PUT requests/month
- CloudFront: 50GB data transfer out, 2M HTTP/HTTPS requests

### After Free Tier
- S3: ~$0.023/GB/month storage, ~$0.0004/1000 requests
- CloudFront: ~$0.085/GB data transfer
- **Estimated cost for low-traffic app**: $1-5/month

---

## Security Best Practices

1. **Never commit AWS credentials** - Use IAM roles in production
2. **Use CloudFront** - Hides S3 bucket origin
3. **Enable versioning** on S3 buckets (rollback capability)
4. **Set up bucket logging** (track access)
5. **Use HTTPS only** via CloudFront

---

## Troubleshooting

### Issue: 403 Access Denied
**Solution**: Check bucket policy allows public read

### Issue: 404 on Refresh
**Solution**: Configure error pages to serve index.html

### Issue: Old version showing
**Solution**: Invalidate CloudFront cache or clear browser cache

### Issue: CORS errors
**Solution**: Add CORS configuration to S3 bucket

---

## Next Steps

After manual deployment works:
- Phase 5: Automate via GitHub Actions
- Phase 6: Add CI/CD pipeline
- Phase 7: Implement blue-green deployments

---

## Commands Summary

```bash
# Create buckets
aws s3 mb s3://bucket-name --region us-east-1

# Enable website hosting
aws s3 website s3://bucket-name --index-document index.html --error-document index.html

# Deploy
aws s3 sync dist/browser s3://bucket-name --delete

# Invalidate CloudFront
aws cloudfront create-invalidation --distribution-id ID --paths "/*"

# List buckets
aws s3 ls

# Delete bucket (cleanup)
aws s3 rb s3://bucket-name --force
```

---

**Ready to deploy?** Complete Steps 1-11 to get your Angular app live on AWS!
