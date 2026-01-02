# AWS Deployment Knowledge Guide
## Complete Reference for S3 & CloudFront Static Website Hosting

**Created**: 2026-01-02
**Version**: 1.0.0
**Project**: Angular Release & Deployment Learning

---

## Table of Contents

1. [Introduction](#introduction)
2. [AWS Fundamentals](#aws-fundamentals)
3. [Amazon S3 Deep Dive](#amazon-s3-deep-dive)
4. [CloudFront CDN Deep Dive](#cloudfront-cdn-deep-dive)
5. [Production vs Learning Setups](#production-vs-learning-setups)
6. [Cost Analysis](#cost-analysis)
7. [Deployment Workflows](#deployment-workflows)
8. [Troubleshooting Guide](#troubleshooting-guide)
9. [Best Practices](#best-practices)
10. [Real-World Examples](#real-world-examples)

---

## Introduction

This guide covers everything you need to know about deploying Angular applications (or any static websites) to AWS using S3 and CloudFront. It's based on hands-on implementation experience and addresses real questions that arise during deployment.

### What You'll Learn

- AWS account setup and IAM permissions
- S3 bucket configuration for static website hosting
- CloudFront CDN setup for global distribution
- Cost optimization strategies
- Production deployment patterns
- Troubleshooting common issues

### Prerequisites

- Basic understanding of web applications
- AWS account with billing enabled
- AWS CLI installed and configured
- Angular application (or any static site)

---

## AWS Fundamentals

### What is AWS?

**Amazon Web Services (AWS)** is a cloud computing platform offering 200+ services including:
- **Compute**: EC2 (virtual servers), Lambda (serverless functions)
- **Storage**: S3 (object storage), EBS (block storage)
- **Networking**: CloudFront (CDN), Route 53 (DNS)
- **Databases**: RDS, DynamoDB
- **And much more...**

For static website hosting, we primarily use:
- **S3** (storage)
- **CloudFront** (distribution/caching)

### AWS Account Structure

```
AWS Account (Root)
  ├── IAM Users (people/services)
  ├── IAM Roles (temporary access)
  ├── IAM Policies (permissions)
  └── Resources (S3, CloudFront, etc.)
```

### IAM (Identity and Access Management)

**Never use root account for daily operations!**

**Best Practice:**
1. Create IAM user for deployments
2. Attach minimal required permissions
3. Use access keys for CLI/automation
4. Rotate keys regularly

**Permissions Model:**
```json
{
  "Who": "Principal (user, role, or *)",
  "What": "Action (s3:GetObject, s3:PutObject)",
  "Where": "Resource (specific bucket/object)",
  "When": "Condition (optional constraints)"
}
```

### AWS CLI Configuration

**Global Configuration Files:**
```
~/.aws/
  ├── credentials    (access keys - NEVER commit to Git!)
  └── config         (region, output format)
```

**Location**: Home directory (`/Users/username/.aws/`)

**Scope**: Global (used by all projects on your machine)

**Configuration**:
```bash
aws configure
# Enter: Access Key ID
# Enter: Secret Access Key
# Enter: Default region (us-east-1)
# Enter: Output format (json)
```

**Multiple Profiles** (for multiple AWS accounts):
```bash
aws configure --profile company-project
aws s3 ls --profile company-project
```

---

## Amazon S3 Deep Dive

### What is S3?

**S3 = Simple Storage Service**

Think of it as **unlimited file storage in the cloud**.

**Key Characteristics:**
- **Object Storage**: Stores files (objects) in containers (buckets)
- **Globally Unique Names**: Bucket names must be unique across ALL AWS accounts
- **Regions**: Data stored in specific geographic locations
- **Durability**: 99.999999999% (11 nines) - virtually never loses data
- **Availability**: 99.99% - accessible 99.99% of the time

### S3 Hierarchy

```
AWS Account
  └── Buckets (containers)
      └── Objects (files)
          ├── Key (file path/name)
          ├── Value (file content)
          ├── Metadata (content-type, etc.)
          └── Version ID (if versioning enabled)
```

**Important**: S3 is **not** a file system! It's object storage.
- No folders (simulated with key prefixes)
- Flat namespace within bucket
- Retrieval by full key path

### Bucket Naming Rules

**Must follow these rules:**
- 3-63 characters long
- Lowercase letters, numbers, hyphens only
- Start with letter or number (not hyphen)
- No underscores, no uppercase
- **Globally unique** across ALL AWS accounts

**Examples:**
```
✅ my-angular-app-prod
✅ company-website-2024
✅ angular-deploy-dev-shree-1767366539

❌ My-App (uppercase)
❌ my_app (underscore)
❌ my-app- (ends with hyphen)
❌ ab (too short)
```

### S3 Static Website Hosting

**Two modes of access:**

**1. S3 REST API (default)**
```
https://bucket-name.s3.amazonaws.com/index.html
https://bucket-name.s3.us-east-1.amazonaws.com/index.html
```
- Returns files as-is
- No index document support
- No error document support
- ❌ Not suitable for SPAs

**2. S3 Static Website Hosting (what we use)**
```
http://bucket-name.s3-website-us-east-1.amazonaws.com
```
- Serves index.html for root requests
- Supports custom error documents
- ✅ Perfect for SPAs (Angular, React, Vue)
- ❌ HTTP only (no HTTPS) - CloudFront adds HTTPS

**Enable Static Website Hosting:**
```bash
aws s3 website s3://bucket-name \
  --index-document index.html \
  --error-document index.html
```

**Why error-document = index.html for SPAs?**
```
User visits: yourapp.com/products
             ↓
S3 looks for: /products file (doesn't exist)
             ↓
S3 returns: Error document (index.html)
             ↓
Angular loads: Handles /products route
             ↓
User sees: Products page ✅
```

### S3 Permissions & Bucket Policies

**Access Control Layers:**
1. **Block Public Access** (account/bucket level safety)
2. **Bucket Policy** (JSON document defining access rules)
3. **ACLs** (legacy, avoid using)

**Public Read Bucket Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::bucket-name/*"
    }
  ]
}
```

**Breakdown:**
- `Version`: Policy language version (always 2012-10-17)
- `Sid`: Statement ID (just a label)
- `Effect`: Allow or Deny
- `Principal`: Who? (* = everyone)
- `Action`: What? (s3:GetObject = read only)
- `Resource`: Which objects? (/* = all in bucket)

**Security**: Only allows **reading** files, not writing/deleting.

**ARN (Amazon Resource Name) Format:**
```
arn:aws:s3:::bucket-name/*
│   │    │  │ │            └─ All objects
│   │    │  │ └─ Bucket name
│   │    │  └─ No region/account (S3 is global namespace)
│   │    └─ Service (s3)
│   └─ Partition (aws, aws-cn, aws-us-gov)
└─ Amazon Resource Name
```

### S3 Deployment Commands

**Upload files (aws s3 sync):**
```bash
aws s3 sync dist/browser s3://bucket-name --delete
```

**What `sync` does:**
- Compares local files vs S3 files
- Uploads new/changed files only
- With `--delete`: Removes S3 files not in local
- Smart and efficient (only changed files)

**vs aws s3 cp (copy):**
```bash
aws s3 cp dist/browser s3://bucket-name --recursive
```
- Uploads ALL files every time
- Slower, more expensive
- Use for one-off uploads

**List buckets:**
```bash
aws s3 ls
```

**List bucket contents:**
```bash
aws s3 ls s3://bucket-name/
```

**Delete bucket:**
```bash
aws s3 rb s3://bucket-name --force
```

### S3 Regions

**What are regions?**
Physical data center locations where your data lives.

**Common regions:**
- `us-east-1`: N. Virginia (default, cheapest)
- `us-west-2`: Oregon
- `eu-west-1`: Ireland
- `ap-south-1`: Mumbai
- `ap-southeast-1`: Singapore

**Choosing a region:**
- Closest to your users (lower latency)
- Compliance requirements (data residency)
- Cost (us-east-1 is cheapest)
- Service availability (some services only in certain regions)

**For static websites with CloudFront:**
Region doesn't matter much (CloudFront caches globally anyway)

### S3 Costs

**Three cost components:**

**1. Storage**
- $0.023/GB/month (first 50 TB)
- Example: 100 MB app = $0.0023/month
- Charged for actual storage used

**2. Requests**
- GET requests: $0.0004 per 1,000 requests
- PUT requests: $0.005 per 1,000 requests
- Example: 10,000 page views = $0.004

**3. Data Transfer OUT**
- $0.09/GB (after free tier)
- Transfer to internet (users downloading)
- Transfer to CloudFront: **FREE** ✅

**Free Tier (first 12 months):**
- 5 GB storage
- 20,000 GET requests
- 2,000 PUT requests
- 15 GB data transfer out

**Real example** (small Angular app):
```
Storage: 5 MB = $0.00012/month
Requests: 5,000 page views = $0.002
Data transfer: 10 GB (bypassed by CloudFront) = $0
────────────────────────────────────────────
Total: ~$0.002/month (essentially free with CloudFront)
```

---

## CloudFront CDN Deep Dive

### What is CloudFront?

**CloudFront = AWS Content Delivery Network (CDN)**

A global network of cache servers that sit between users and your origin (S3).

**Key Concept**: Distribution, not storage
- CloudFront doesn't store your files permanently
- It **caches** copies at edge locations
- Always fetches from origin (S3) when cache is empty

### The Problem CloudFront Solves

**Without CloudFront:**
```
User in Tokyo → S3 in Virginia (12,000 km away)
Response time: 500-1000ms (half a second delay)
```

**With CloudFront:**
```
User in Tokyo → CloudFront Edge in Tokyo (local)
Response time: 20-50ms (instant!)

Edge location caches the file, so:
- Next Tokyo user: Even faster (pure cache hit)
- S3 only contacted on cache miss
```

### CloudFront Architecture

```
                    Users Worldwide
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
   Edge (USA)       Edge (Europe)      Edge (Asia)
        │                 │                 │
        └─────────────────┼─────────────────┘
                          │
                    CloudFront
                          │
                     Origin (S3)
```

**450+ Edge Locations:**
- North America: ~200
- Europe: ~100
- Asia: ~100
- South America, Africa, Australia: ~50

### CloudFront vs S3: NOT a Replacement

**Common Misconception**: CloudFront replaces S3 ❌

**Reality**: CloudFront sits **on top of** S3 ✅

```
Architecture:

S3 Bucket (Storage Layer)
  ↓
CloudFront (Distribution/Caching Layer)
  ↓
Users (Browser)
```

**S3 = Storage** (permanent home of files)
**CloudFront = Cache** (temporary copies for speed)

**After CloudFront setup, you have BOTH:**

1. **S3 URL** (still works):
   ```
   http://bucket-name.s3-website-us-east-1.amazonaws.com
   ```
   - Direct access to S3
   - HTTP only
   - Slower for distant users

2. **CloudFront URL** (new):
   ```
   https://d123abc.cloudfront.net
   ```
   - Cached access via edge locations
   - HTTPS enabled
   - Fast globally

**Both URLs serve the same files from S3.**

### CloudFront Key Concepts

#### 1. Distribution

A CloudFront configuration that defines:
- **Origin**: Where to get files (S3, custom server, etc.)
- **Behaviors**: Caching rules, allowed methods
- **Restrictions**: Geo-blocking, security settings
- **SSL/TLS**: HTTPS configuration

**Each distribution gets unique domain:**
```
dABC123DEF456.cloudfront.net
```

#### 2. Origin

The source of your content.

**Types:**
- **S3 Bucket** (what we use)
- **Custom HTTP server** (EC2, your own server)
- **Media services** (MediaPackage, MediaStore)

**Important for S3 Static Websites:**
Use website endpoint, NOT REST API endpoint:
```
✅ bucket-name.s3-website-us-east-1.amazonaws.com (static website)
❌ bucket-name.s3.amazonaws.com (REST API)
```

#### 3. Cache Behavior & TTL

**TTL = Time To Live** (how long to cache files)

**Default behaviors:**
```
index.html:      Cache for 24 hours
main-ABC123.js:  Cache for 1 year (hashed filename = safe)
images:          Cache for 1 week
API responses:   Don't cache (dynamic)
```

**Why hashed filenames matter:**
```
Old deploy: main-ABC123.js (cached for 1 year)
New deploy: main-XYZ789.js (different hash = new file)

index.html references main-XYZ789.js
→ Cache miss for new file
→ CloudFront fetches from S3
→ Users get new code immediately ✅
```

**Cache Policies:**
- `CachingOptimized`: AWS managed, good default
- `CachingDisabled`: Don't cache (for dynamic content)
- Custom policies: Define your own rules

#### 4. Cache Invalidation

**Problem:**
```
Deploy new code to S3
CloudFront still has old files cached
Users see old version for hours ❌
```

**Solution:**
```bash
aws cloudfront create-invalidation \
  --distribution-id E123ABC \
  --paths "/*"
```

**What happens:**
1. CloudFront deletes cached files at edge locations
2. Next request fetches fresh file from S3
3. New file gets cached

**Cost:**
- First 1,000 invalidations/month: **FREE**
- Additional: $0.005 per path

**Best Practice:**
Invalidate only `index.html` (not hashed files):
```bash
aws cloudfront create-invalidation \
  --distribution-id E123ABC \
  --paths "/index.html"
```

Why? Hashed files (main-XYZ.js) auto-update via new filenames.

#### 5. Error Pages & SPA Routing

**Problem for SPAs:**
```
User visits: yourapp.com/products
CloudFront: "Looking for /products file in S3..."
S3: "File not found"
CloudFront: Returns 403 Forbidden
User: Sees error page ❌
```

**Solution: Custom Error Responses**

Configure CloudFront to return `index.html` for errors:

**403 Forbidden:**
- Response page: `/index.html`
- HTTP code: `200 OK`

**404 Not Found:**
- Response page: `/index.html`
- HTTP code: `200 OK`

**Result:**
```
User visits: yourapp.com/products
CloudFront: "Looking for /products..."
S3: "File not found" (403)
CloudFront: "Custom response: return index.html with 200"
Angular: Loads and handles /products route
User: Sees products page ✅
```

**Error Caching TTL:**
- How long CloudFront caches error responses
- Default: 10 seconds
- For SPAs: Keep low (0-10 seconds) for quick deploy visibility

#### 6. HTTPS / SSL

**S3 Static Website:**
- ❌ HTTP only
- ❌ No SSL support
- ❌ Browser shows "Not Secure"

**CloudFront:**
- ✅ HTTPS by default
- ✅ Free SSL certificate (*.cloudfront.net)
- ✅ Can use custom SSL (your domain)

**Certificate options:**
1. **Default CloudFront certificate** (free):
   ```
   https://d123abc.cloudfront.net
   ```
   - Automatic, no setup
   - *.cloudfront.net wildcard

2. **Custom domain certificate** (free via ACM):
   ```
   https://yourapp.com
   ```
   - Requires AWS Certificate Manager
   - Domain verification needed
   - Professional appearance

### CloudFront Deployment Flow

**First Request (Cache Miss):**
```
1. User (Tokyo) → CloudFront Edge (Tokyo)
   "Give me index.html"

2. Edge → Origin (S3 in Virginia)
   "I don't have index.html, fetching..."

3. S3 → Edge
   "Here's index.html" (500ms)

4. Edge caches file (TTL: 24 hours)

5. Edge → User
   "Here's index.html" (total: ~550ms)
```

**Subsequent Requests (Cache Hit):**
```
1. User (Tokyo) → CloudFront Edge (Tokyo)
   "Give me index.html"

2. Edge → User
   "Here from cache!" (20ms)

   (S3 never contacted)
```

### CloudFront Costs

**Free Tier (12 months):**
- 50 GB data transfer out
- 2 million HTTP/HTTPS requests

**After free tier:**
- **Data transfer**: $0.085/GB (first 10 TB)
- **HTTPS requests**: $0.0100 per 10,000 requests
- **HTTP requests**: $0.0075 per 10,000 requests
- **Invalidations**: First 1,000/month free, then $0.005/path

**Real example** (10,000 visitors/month, 2 MB avg):
```
Data transfer: 20 GB × $0.085 = $1.70
Requests: 10,000 × $0.001 = $0.01
Invalidations: 30 deployments (free)
─────────────────────────────────────
Total: ~$1.71/month
```

**vs S3 direct** (same traffic):
```
S3 requests: 10,000 × $0.0004 = $0.04
S3 data transfer: 20 GB × $0.09 = $1.80
─────────────────────────────────────
Total: ~$1.84/month
```

**CloudFront can be CHEAPER** due to:
- Reduced S3 requests (caching)
- Reduced S3 data transfer (edge serving)
- Slightly lower per-GB cost

### CloudFront CLI Commands

**Create invalidation:**
```bash
aws cloudfront create-invalidation \
  --distribution-id E123ABC \
  --paths "/*"
```

**List distributions:**
```bash
aws cloudfront list-distributions
```

**Get distribution config:**
```bash
aws cloudfront get-distribution \
  --id E123ABC
```

**Wait for deployment:**
```bash
aws cloudfront wait distribution-deployed \
  --id E123ABC
```

---

## Production vs Learning Setups

### Multi-Environment Strategy

**Industry Standard:**
```
Development → S3 only (http://)
QA          → S3 only (http://)
Staging     → S3 only (http://) [or CloudFront if stakeholders need HTTPS]
Production  → S3 + CloudFront (https://)
```

**Why not CloudFront for all?**

**Development:**
- Internal only (developers)
- Changes 20+ times/day
- Caching is annoying (want fresh code immediately)
- HTTP is fine for local testing
- Cost: Unnecessary

**QA:**
- Internal QA team (5-10 people)
- Frequent deployments (10+ times/day)
- Testing functionality, not performance
- HTTP acceptable
- Cost: Unnecessary

**Staging:**
- **Gray area** - depends on use case
- Option A: S3 only (most common)
- Option B: CloudFront if:
  - Stakeholders require HTTPS
  - Client demos need professional appearance
  - Testing payment integrations (HTTPS required)
  - Must mirror production exactly

**Production:**
- **Always CloudFront** ✅
- Real users worldwide
- HTTPS required (security, trust, SEO)
- Speed matters (UX, conversion rates)
- Professional domain (yourapp.com)
- Cost: Worth it

### When to Add CloudFront to Non-Prod

**Scenario 1: Global Team**
```
QA team in India + Dev in USA + Stakeholders in Europe
S3 in Virginia = slow for everyone except USA team

Solution: Add CloudFront to staging (or choose multi-region S3)
```

**Scenario 2: Client Demos**
```
Stakeholders see "Not Secure" warning on HTTP staging URL
Looks unprofessional

Solution: Add CloudFront to staging
```

**Scenario 3: Integration Testing**
```
Testing Stripe payments (requires HTTPS)
Testing OAuth providers (HTTPS callbacks)

Solution: Add CloudFront to staging/QA
```

**For 90% of companies**: S3-only for non-prod is standard and acceptable.

### Real-World Production Stack

**Option 1: S3 + CloudFront (Serverless)**
```
User
  ↓
Route 53 (DNS: yourapp.com)
  ↓
CloudFront (HTTPS, caching)
  ↓
S3 (storage, origin)
```

**Pros:**
- Zero server management
- Auto-scaling
- Cheap (~$2-5/month for small apps)
- Simple deployment

**Cons:**
- Less control over HTTP headers
- Can't run server-side logic
- No SSR (Server-Side Rendering)

**Used by:** Startups, marketing sites, documentation sites

---

**Option 2: Docker + Kubernetes/ECS**
```
User
  ↓
Load Balancer (ALB/NLB)
  ↓
Docker Container (nginx + Angular)
  ↓
Auto-scaling container instances
```

**Pros:**
- Full control over nginx config
- Can add server-side logic
- Supports SSR
- Industry standard

**Cons:**
- More complex
- Higher cost (~$20-50/month minimum)
- Requires DevOps knowledge

**Used by:** Enterprises, SaaS products, complex applications

---

**Option 3: Vercel/Netlify (Managed)**
```
Git Push
  ↓
Auto-deploy to global CDN
  ↓
HTTPS, custom domain, serverless functions
```

**Pros:**
- Zero config
- Git integration
- Generous free tier
- Fast deployments

**Cons:**
- Vendor lock-in
- Less control
- Can get expensive at scale

**Used by:** Modern web developers, Next.js/React apps, quick MVPs

---

## Cost Analysis

### S3 Only Setup

**Small App (5 MB, 10,000 visitors/month):**
```
Storage: 5 MB × $0.023/GB = $0.00012/month
Requests: 10,000 × $0.0004 = $0.004/month
Data transfer: 50 GB × $0.09 = $4.50/month
──────────────────────────────────────────────
Total: ~$4.50/month
```

### S3 + CloudFront Setup

**Same app (5 MB, 10,000 visitors/month):**
```
S3:
  Storage: $0.00012/month
  Requests: ~100 (cache misses) = $0.00004/month
  Data transfer to CloudFront: FREE

CloudFront:
  Data transfer: 50 GB × $0.085 = $4.25/month
  Requests: 10,000 × $0.001 = $0.01/month
──────────────────────────────────────────────
Total: ~$4.26/month (CHEAPER than S3 only!)
```

**Savings breakdown:**
- S3 requests: 99% reduction (caching)
- Data transfer: Slightly cheaper per GB
- Total: ~$0.24/month savings + HTTPS + speed

### Free Tier Coverage

**First 12 months:**
```
S3:
  5 GB storage (100× a 5 MB app)
  20,000 GET requests (~2,000 visitors)
  15 GB data transfer out

CloudFront:
  50 GB data transfer (~5,000 visitors)
  2 million requests (more than enough)
```

**For learning project:**
Both S3 and CloudFront will be **FREE** for at least 12 months.

### Cost Optimization Tips

**1. Enable Gzip/Brotli Compression**
```
5 MB uncompressed → 1 MB compressed
5× reduction in data transfer costs
```

**2. Set Proper Cache TTLs**
```
Long TTL for static assets (images, fonts)
Short TTL for HTML (or use invalidation)
```

**3. Invalidate Smartly**
```
✅ Invalidate /index.html only (free, effective)
❌ Invalidate /* (expensive, unnecessary for hashed files)
```

**4. Use CloudFront Price Classes**
```
All edge locations: $0.085/GB
North America + Europe only: $0.080/GB (cheaper)
```

**5. Monitor with AWS Cost Explorer**
```
Track actual costs
Set billing alarms
Identify unexpected spikes
```

---

## Deployment Workflows

### Manual Deployment (What We Did)

**Step-by-step:**
```bash
# 1. Build Angular app
npm run build --configuration=production

# 2. Swap environment config
cp src/assets/config/environment.prod.json \
   dist/browser/assets/config/environment.json

# 3. Upload to S3
aws s3 sync dist/browser s3://bucket-name --delete

# 4. Invalidate CloudFront (production only)
aws cloudfront create-invalidation \
  --distribution-id E123ABC \
  --paths "/*"
```

**Pros:**
- Full control
- Easy to understand
- Good for learning

**Cons:**
- Manual process
- Error-prone
- Slow

### Automated Deployment Script

**Our deploy.sh script:**
```bash
./deploy.sh dev      # Deploy to development
./deploy.sh qa       # Deploy to QA
./deploy.sh staging  # Deploy to staging
./deploy.sh prod     # Deploy to production (with CloudFront invalidation)
```

**Features:**
- Validates environment parameter
- Builds Angular app
- Swaps correct environment config
- Uploads to correct S3 bucket
- Invalidates CloudFront cache (prod only)
- Color-coded output
- Error handling

**Pros:**
- Repeatable
- Less error-prone
- Fast
- Documented in code

**Cons:**
- Still manual trigger
- No automated testing
- No rollback strategy

### CI/CD Deployment (Next Phase)

**GitHub Actions workflow:**
```yaml
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - Checkout code
      - Run tests
      - Build app
      - Deploy to S3
      - Invalidate CloudFront
```

**Pros:**
- Fully automated
- Triggered by git push
- Includes testing
- Deployment history
- Rollback capability

**Future implementation** in Phase 5-6 of this project.

### Blue-Green Deployment (Advanced)

**Strategy:**
```
Blue Environment (current prod)
  ↓
Deploy to Green Environment (new version)
  ↓
Test Green Environment
  ↓
Switch CloudFront to Green
  ↓
Blue becomes standby (instant rollback)
```

**Implementation:**
- Two S3 buckets (blue, green)
- One CloudFront distribution
- Switch origin on deploy
- Instant rollback if issues

**Future implementation** in Phase 8 of this project.

---

## Troubleshooting Guide

### S3 Issues

#### Issue: 403 Forbidden on S3 URL

**Symptoms:**
```
AccessDenied error when visiting bucket URL
```

**Causes:**
1. Bucket policy not applied
2. Block Public Access enabled
3. Bucket not configured for website hosting

**Solutions:**
```bash
# 1. Check bucket policy
aws s3api get-bucket-policy --bucket bucket-name

# 2. Disable Block Public Access
aws s3api put-public-access-block \
  --bucket bucket-name \
  --public-access-block-configuration \
  "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# 3. Enable website hosting
aws s3 website s3://bucket-name \
  --index-document index.html \
  --error-document index.html

# 4. Apply bucket policy
aws s3api put-bucket-policy \
  --bucket bucket-name \
  --policy file://policy.json
```

#### Issue: 404 on Angular Routes

**Symptoms:**
```
Direct URL like /products returns 404
Works when navigating from home page
```

**Cause:**
Error document not configured

**Solution:**
```bash
aws s3 website s3://bucket-name \
  --index-document index.html \
  --error-document index.html  # This is critical for SPAs
```

#### Issue: Old Version Showing After Deploy

**Symptoms:**
```
Deployed new code but seeing old version
```

**Causes:**
1. Browser cache
2. CloudFront cache (if using)
3. Wrong environment deployed

**Solutions:**
```bash
# 1. Hard refresh browser
Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows)

# 2. Check S3 directly (bypass CloudFront)
open http://bucket-name.s3-website-us-east-1.amazonaws.com

# 3. Verify files uploaded
aws s3 ls s3://bucket-name/ --recursive

# 4. Check file timestamps
aws s3 ls s3://bucket-name/ --recursive --human-readable
```

### CloudFront Issues

#### Issue: 403 Forbidden on CloudFront URL

**Symptoms:**
```
CloudFront returns 403 for all routes except root
```

**Cause:**
Custom error responses not configured

**Solution:**
Configure error pages in CloudFront console:
- 403 → `/index.html` (200 OK)
- 404 → `/index.html` (200 OK)

Or via CLI:
```bash
aws cloudfront update-distribution \
  --id E123ABC \
  --custom-error-responses file://error-config.json
```

#### Issue: CloudFront Serving Old Content

**Symptoms:**
```
Deployed to S3 but CloudFront shows old version
S3 direct URL shows new version
```

**Cause:**
CloudFront cache not invalidated

**Solution:**
```bash
# Invalidate all files
aws cloudfront create-invalidation \
  --distribution-id E123ABC \
  --paths "/*"

# Or just index.html (recommended)
aws cloudfront create-invalidation \
  --distribution-id E123ABC \
  --paths "/index.html"

# Check invalidation status
aws cloudfront get-invalidation \
  --distribution-id E123ABC \
  --id INVALIDATION_ID
```

#### Issue: Distribution Still Deploying

**Symptoms:**
```
Created distribution hours ago, still "Deploying"
```

**Normal behavior:**
- First deployment: 15-30 minutes
- Configuration changes: 5-15 minutes

**If stuck >1 hour:**
```bash
# Check distribution status
aws cloudfront get-distribution --id E123ABC

# Look for errors in CloudWatch
# Contact AWS Support if truly stuck
```

### AWS CLI Issues

#### Issue: Credentials Not Found

**Symptoms:**
```
Unable to locate credentials
```

**Solutions:**
```bash
# 1. Verify credentials file exists
ls -la ~/.aws/

# 2. Reconfigure AWS CLI
aws configure

# 3. Check profile (if using multiple)
aws configure list
export AWS_PROFILE=your-profile
```

#### Issue: Permission Denied

**Symptoms:**
```
AccessDenied for S3 operation
User not authorized to perform action
```

**Solutions:**
```bash
# 1. Check who you are
aws sts get-caller-identity

# 2. Verify IAM permissions
# Go to AWS Console → IAM → Users → Your user
# Check attached policies

# 3. Ensure policies include required actions:
# s3:PutObject, s3:GetObject, s3:DeleteObject, s3:ListBucket
```

### General Debugging

**Check actual HTTP response:**
```bash
# S3
curl -I http://bucket-name.s3-website-us-east-1.amazonaws.com

# CloudFront
curl -I https://d123abc.cloudfront.net

# Look for:
# - HTTP status code
# - Content-Type header
# - Cache headers
# - X-Cache header (CloudFront: Hit/Miss)
```

**Verify DNS:**
```bash
nslookup d123abc.cloudfront.net
dig d123abc.cloudfront.net
```

**Check S3 bucket directly:**
```bash
# List files
aws s3 ls s3://bucket-name/ --recursive

# Download file
aws s3 cp s3://bucket-name/index.html ./test-index.html

# Check content
cat test-index.html
```

---

## Best Practices

### Security

**1. Never Commit AWS Credentials**
```bash
# Add to .gitignore
.env
.env.aws
*.pem
credentials
```

**2. Use IAM Roles in Production**
```
Instead of access keys, use:
- EC2 Instance Roles
- ECS Task Roles
- Lambda Execution Roles
```

**3. Enable S3 Versioning**
```bash
aws s3api put-bucket-versioning \
  --bucket bucket-name \
  --versioning-configuration Status=Enabled
```

**Benefits:**
- Accidental deletion recovery
- Rollback capability
- Audit trail

**4. Enable CloudFront Access Logging**
```
Track who accesses your site
Useful for analytics and security
```

**5. Use HTTPS Only (CloudFront)**
```
Viewer Protocol Policy: Redirect HTTP to HTTPS
Ensures all traffic encrypted
```

**6. Regular Security Audits**
```bash
# Check for public buckets
aws s3api list-buckets --query 'Buckets[*].Name' | xargs -I {} \
  aws s3api get-bucket-policy --bucket {}

# Review IAM policies
aws iam list-attached-user-policies --user-name your-user
```

### Performance

**1. Optimize Images**
```
Use modern formats (WebP, AVIF)
Compress images (TinyPNG, ImageOptim)
Lazy load off-screen images
```

**2. Enable Compression**
```
CloudFront: Automatic Gzip/Brotli
nginx (if using containers): Enable gzip
```

**3. Use HTTP/2**
```
CloudFront: Enabled by default
Faster multiplexing, header compression
```

**4. Set Proper Cache Headers**
```html
<!-- index.html: Short cache -->
Cache-Control: max-age=300 (5 minutes)

<!-- Hashed assets: Long cache -->
main-ABC123.js: Cache-Control: max-age=31536000 (1 year)
```

**5. Minimize JavaScript**
```bash
# Angular production build does this automatically
ng build --configuration=production

# Results in minified, tree-shaken bundles
```

**6. Use CDN for Third-Party Libraries**
```html
<!-- Instead of bundling, use CDN -->
<script src="https://cdn.jsdelivr.net/npm/vue@3"></script>
```

### Cost Optimization

**1. Delete Unused Buckets**
```bash
# List all buckets
aws s3 ls

# Delete empty buckets
aws s3 rb s3://bucket-name

# Delete bucket with contents
aws s3 rb s3://bucket-name --force
```

**2. Monitor Costs**
```
Enable Cost Explorer
Set billing alerts ($10, $50, $100)
Review monthly bills
```

**3. Use Lifecycle Policies**
```bash
# Auto-delete old versions after 30 days
aws s3api put-bucket-lifecycle-configuration \
  --bucket bucket-name \
  --lifecycle-configuration file://lifecycle.json
```

**4. Choose Right CloudFront Price Class**
```
All locations: Best performance, higher cost
North America + Europe: Good performance, lower cost
```

**5. Optimize Invalidations**
```bash
# ✅ Efficient
aws cloudfront create-invalidation \
  --paths "/index.html"

# ❌ Wasteful (charges after 1,000/month)
aws cloudfront create-invalidation \
  --paths "/*"
```

### Operations

**1. Use Infrastructure as Code**
```
Future: Terraform or CloudFormation
Version control your infrastructure
Repeatable deployments
```

**2. Tag Resources**
```bash
aws s3api put-bucket-tagging \
  --bucket bucket-name \
  --tagging 'TagSet=[{Key=Environment,Value=Production},{Key=Project,Value=AngularApp}]'
```

**3. Enable Logging**
```
S3 Access Logs
CloudFront Access Logs
CloudWatch Metrics
```

**4. Automate Deployments**
```
CI/CD pipelines (Phase 5-6)
Automated testing
Deployment notifications
```

**5. Document Everything**
```
Deployment procedures
Rollback procedures
Emergency contacts
Runbooks for common issues
```

### Development Workflow

**1. Environment Parity**
```
Dev, QA, Staging, Prod should be similar
Same deployment process for all
Catch issues before production
```

**2. Test Deployments**
```bash
# Deploy to dev first
./deploy.sh dev

# Verify in browser
# Run automated tests
# Then promote to prod
./deploy.sh prod
```

**3. Use Feature Flags**
```typescript
if (config.features.enableNewCheckout) {
  // New checkout flow
} else {
  // Old checkout flow
}
```

**4. Monitor After Deploy**
```
Check error logs
Monitor user analytics
Watch for spike in errors
Have rollback plan ready
```

---

## Real-World Examples

### Example 1: Marketing Website

**Requirements:**
- 10 static pages
- Low traffic (1,000 visitors/month)
- Need HTTPS for SEO
- Budget: <$5/month

**Solution:**
```
S3 + CloudFront

Setup:
- Single S3 bucket (prod only)
- CloudFront distribution
- Route 53 custom domain

Cost: ~$1-2/month (within free tier first year)
```

### Example 2: SaaS Application

**Requirements:**
- Angular app with multiple routes
- 50,000 users/month
- Global users (US, Europe, Asia)
- Need dev/staging/prod environments
- Budget: <$50/month

**Solution:**
```
Multi-environment S3 + CloudFront (prod only)

Setup:
- 3 S3 buckets (dev, staging, prod)
- CloudFront for prod only
- CI/CD pipeline
- Automated testing

Cost:
- S3: ~$2/month
- CloudFront: ~$25/month
- Total: ~$27/month
```

### Example 3: Enterprise E-commerce

**Requirements:**
- High traffic (1M+ visitors/month)
- Global distribution
- 99.99% uptime SLA
- Server-Side Rendering needed
- Complex deployment pipeline

**Solution:**
```
Docker + Kubernetes + CloudFront

Setup:
- Containerized Angular + nginx
- AWS EKS (Kubernetes)
- CloudFront for global CDN
- Blue-green deployments
- Multi-region setup

Cost: ~$500-1000/month
```

### Example 4: Documentation Site

**Requirements:**
- Simple static site
- Open source project
- Free hosting
- Easy for contributors

**Solution:**
```
Netlify or GitHub Pages

Setup:
- Git push to deploy
- Free HTTPS
- Free CDN
- Free hosting

Cost: $0/month
```

### Example 5: Internal Dashboard

**Requirements:**
- Internal tool (10 employees)
- VPN access only
- No internet exposure
- Low cost

**Solution:**
```
S3 with VPC endpoint (no CloudFront)

Setup:
- S3 bucket (private)
- VPC endpoint
- IAM authentication
- No public access

Cost: <$1/month
```

---

## Appendix

### Useful AWS Resources

**Documentation:**
- [S3 Developer Guide](https://docs.aws.amazon.com/s3/)
- [CloudFront Developer Guide](https://docs.aws.amazon.com/cloudfront/)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/)

**Pricing Calculators:**
- [AWS Simple Monthly Calculator](https://calculator.aws/)
- [S3 Pricing](https://aws.amazon.com/s3/pricing/)
- [CloudFront Pricing](https://aws.amazon.com/cloudfront/pricing/)

**Learning:**
- [AWS Free Tier](https://aws.amazon.com/free/)
- [AWS Training](https://aws.amazon.com/training/)

### Glossary

**ARN**: Amazon Resource Name (unique identifier)
**CDN**: Content Delivery Network
**Edge Location**: CloudFront cache server location
**IAM**: Identity and Access Management
**Origin**: Source of content (S3, custom server)
**SPA**: Single Page Application
**TTL**: Time To Live (cache duration)
**VPC**: Virtual Private Cloud

### Version History

- **v1.0.0** (2026-01-02): Initial comprehensive guide
  - S3 static website hosting
  - CloudFront CDN setup
  - Deployment automation
  - Cost analysis
  - Best practices

---

**End of AWS Knowledge Guide**

*For questions or updates, refer to the main project documentation.*
