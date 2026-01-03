# AWS ECS Deployment Guide (Docker Containers)

## 📋 Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [AWS Resources Setup](#aws-resources-setup)
4. [GitHub Configuration](#github-configuration)
5. [Deployment Process](#deployment-process)
6. [Monitoring & Troubleshooting](#monitoring--troubleshooting)
7. [Cost Management](#cost-management)
8. [Cleanup Instructions](#cleanup-instructions)

---

## Overview

### What is ECS?

**ECS (Elastic Container Service)** is AWS's container orchestration service that manages Docker containers at scale.

**Mental Model - The Factory Analogy:**
- **Docker Image** = Product blueprint
- **ECR (Container Registry)** = Blueprint storage warehouse
- **ECS Cluster** = Factory building
- **ECS Service** = Assembly line manager
- **ECS Task** = Worker following the blueprint
- **Fargate** = Outsourced workers (you don't manage the servers)

### ECS vs S3 Deployment

| Feature | S3 + CloudFront (Current) | ECS + Fargate (This Guide) |
|---------|---------------------------|----------------------------|
| **Type** | Static file hosting | Container orchestration |
| **Use Case** | SPAs, static sites | Full-stack apps, APIs, dynamic content |
| **Cost** | ~$1-2/month | ~$30/month per environment |
| **Scaling** | Automatic (CloudFront CDN) | Configurable (task count) |
| **Deployment** | Upload files to S3 | Deploy Docker containers |
| **Health Checks** | Basic | Advanced (container health, load balancer) |
| **Load Balancing** | CloudFront | Application Load Balancer (ALB) |

### Architecture Overview

```
GitHub Actions → Build Docker Image → Push to ECR → Deploy to ECS → ALB → Users

     Code              Dockerfile          Registry      Fargate Tasks    Traffic
   Push/PR             Multi-stage         Storage       Running on       Distribution
                       Build Process                     AWS Managed
                                                        Infrastructure
```

---

## Prerequisites

### 1. AWS Account Requirements
- Active AWS account
- IAM user with appropriate permissions
- AWS CLI installed (optional, but helpful)

### 2. Local Tools
- ✅ Docker installed (you have this)
- ✅ Docker Compose (you have this)
- ✅ GitHub account (you have this)
- AWS CLI (optional): `brew install awscli`

### 3. Completed Steps
- ✅ Frontend Dockerfile created
- ✅ docker-compose.yml configured
- ✅ GitHub Actions workflow (`deploy-ecs.yml`) ready
- ✅ Task definition templates created

---

## AWS Resources Setup

### Step 1: Create ECR Repository

**What**: ECR stores your Docker images (like Docker Hub, but AWS-managed)

**Commands**:
```bash
# Set region
export AWS_REGION=us-east-1

# Create ECR repository
aws ecr create-repository \
  --repository-name angular-frontend \
  --region $AWS_REGION

# Enable lifecycle policy (auto-delete old images)
aws ecr put-lifecycle-policy \
  --repository-name angular-frontend \
  --region $AWS_REGION \
  --lifecycle-policy-text '{
    "rules": [{
      "rulePriority": 1,
      "description": "Keep last 10 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": { "type": "expire" }
    }]
  }'
```

**Via AWS Console**:
1. Go to: AWS Console → ECR
2. Click: "Create repository"
3. Name: `angular-frontend`
4. Leave defaults, click "Create"

**Expected Output**:
```json
{
  "repository": {
    "repositoryArn": "arn:aws:ecr:us-east-1:123456789012:repository/angular-frontend",
    "repositoryUri": "123456789012.dkr.ecr.us-east-1.amazonaws.com/angular-frontend"
  }
}
```

**Copy the `repositoryUri`** - you'll need it later!

---

### Step 2: Create IAM Roles

**Two roles needed:**
1. **ecsTaskExecutionRole** - Pulls images from ECR, writes logs
2. **ecsTaskRole** - Permissions for your app (if it needs AWS services)

**Commands**:
```bash
# Create Task Execution Role
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": { "Service": "ecs-tasks.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }]
  }'

# Attach AWS managed policy
aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

# Create Task Role (for app permissions)
aws iam create-role \
  --role-name ecsTaskRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": { "Service": "ecs-tasks.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }]
  }'
```

**Via AWS Console**:
1. Go to: IAM → Roles → Create role
2. Select: "AWS service" → "Elastic Container Service"
3. Use case: "Elastic Container Service Task"
4. Attach policy: `AmazonECSTaskExecutionRolePolicy`
5. Name: `ecsTaskExecutionRole`
6. Repeat for `ecsTaskRole` (no policies needed unless app uses AWS services)

---

### Step 3: Create VPC and Subnets (if needed)

**Check if you have default VPC**:
```bash
aws ec2 describe-vpcs --filters "Name=isDefault,Values=true"
```

If you have a default VPC, **skip this step**. Otherwise:

```bash
# Create VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16

# Create subnets (need at least 2 for ALB)
aws ec2 create-subnet --vpc-id vpc-xxxxx --cidr-block 10.0.1.0/24 --availability-zone us-east-1a
aws ec2 create-subnet --vpc-id vpc-xxxxx --cidr-block 10.0.2.0/24 --availability-zone us-east-1b
```

---

### Step 4: Create CloudWatch Log Groups

**Purpose**: Store container logs

```bash
# Create log groups for each environment
for env in dev qa staging prod; do
  aws logs create-log-group \
    --log-group-name /ecs/frontend-$env \
    --region $AWS_REGION
done
```

---

### Step 5: Create ECS Clusters

**One cluster per environment:**

```bash
# Development
aws ecs create-cluster \
  --cluster-name angular-app-dev \
  --region $AWS_REGION

# QA
aws ecs create-cluster \
  --cluster-name angular-app-qa \
  --region $AWS_REGION

# Staging
aws ecs create-cluster \
  --cluster-name angular-app-staging \
  --region $AWS_REGION

# Production
aws ecs create-cluster \
  --cluster-name angular-app-prod \
  --region $AWS_REGION
```

**Via Console**:
1. Go to: ECS → Clusters → Create cluster
2. Name: `angular-app-dev`
3. Infrastructure: "AWS Fargate (serverless)"
4. Click "Create"
5. Repeat for qa, staging, prod

---

### Step 6: Update Task Definitions

**Edit the task definition files** (.aws/task-definition-*.json) and replace placeholders:

1. Replace `YOUR_ACCOUNT_ID` with your AWS account ID
   ```bash
   # Get your account ID
   aws sts get-caller-identity --query Account --output text
   ```

2. Update task definitions:
   ```bash
   ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

   # Replace in all task definitions
   cd .aws
   for file in task-definition-*.json; do
     sed -i "s/YOUR_ACCOUNT_ID/$ACCOUNT_ID/g" "$file"
   done
   ```

---

### Step 7: Register Task Definitions

```bash
cd .aws

# Register each task definition
aws ecs register-task-definition \
  --cli-input-json file://task-definition-dev.json

aws ecs register-task-definition \
  --cli-input-json file://task-definition-qa.json

aws ecs register-task-definition \
  --cli-input-json file://task-definition-staging.json

aws ecs register-task-definition \
  --cli-input-json file://task-definition-prod.json
```

---

### Step 8: Create Application Load Balancers

**One ALB per environment** (or share one for dev/qa to save cost)

**Via Console** (easier for first time):
1. Go to: EC2 → Load Balancers → Create load balancer
2. Type: Application Load Balancer
3. Name: `frontend-alb-dev`
4. Scheme: Internet-facing
5. Network: Select VPC and at least 2 subnets
6. Security groups: Create or select one allowing HTTP (port 80)
7. Listener: HTTP:80
8. Create target group:
   - Type: IP addresses
   - Name: `frontend-tg-dev`
   - Protocol: HTTP
   - Port: 80
   - Health check path: `/`
9. Create

**Copy the ALB DNS name** (e.g., `dev-frontend-alb-12345678.us-east-1.elb.amazonaws.com`)

Repeat for qa, staging, prod.

---

### Step 9: Create ECS Services

**One service per environment** - this connects everything together.

```bash
# Development Service
aws ecs create-service \
  --cluster angular-app-dev \
  --service-name frontend-service-dev \
  --task-definition frontend-task-dev \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxxxx,subnet-yyyyy],securityGroups=[sg-xxxxx],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/frontend-tg-dev/xxxxx,containerName=angular-frontend,containerPort=80"
```

**Via Console** (recommended):
1. Go to: ECS → Clusters → angular-app-dev → Services → Create
2. Launch type: Fargate
3. Task definition: frontend-task-dev (latest)
4. Service name: `frontend-service-dev`
5. Number of tasks: 1
6. Deployment type: Rolling update
7. Load balancing: Application Load Balancer
8. Select ALB: `frontend-alb-dev`
9. Container: angular-frontend:80
10. Target group: frontend-tg-dev
11. Health check grace period: 60 seconds
12. Create

Repeat for qa, staging, prod.

---

## GitHub Configuration

### Step 1: Update Workflow URLs

Edit `.github/workflows/deploy-ecs.yml` and replace ALB URLs:

```yaml
# Find these lines and update with your actual ALB DNS names:
environment:
  url: http://dev-frontend-alb-YOUR_ALB_ID.us-east-1.elb.amazonaws.com
```

### Step 2: GitHub Secrets (Already Set)

Verify these secrets exist in GitHub:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### Step 3: GitHub Environments

Create/verify GitHub environments with protection rules:

1. Go to: GitHub Repo → Settings → Environments
2. Ensure environments exist:
   - `development` (no approval)
   - `qa` (no approval)
   - `staging` (no approval)
   - `production` (requires approval ✓)

---

## Deployment Process

### Automatic Deployments

**Development**:
```bash
git checkout develop
git add .
git commit -m "feat: add new feature"
git push origin develop
# → Automatically deploys to Development ECS
```

**Staging**:
```bash
git checkout staging
git merge develop
git push origin staging
# → Automatically deploys to Staging ECS
```

**Production**:
```bash
git checkout main
git merge staging
git push origin main
# → Waits for GitHub approval
# → Then deploys to Production ECS
```

### Manual QA Deployment

1. Go to: GitHub → Actions → "Deploy to AWS ECS (Docker)"
2. Click: "Run workflow"
3. Select:
   - Branch: any branch
   - Environment: qa
4. Click: "Run workflow"

### Deployment Flow

```
GitHub Push → Workflow Triggered → Build & Test → Build Docker Image
    ↓
Push to ECR → Update Task Definition → Deploy to ECS → Health Check
    ↓
Success: Traffic routed to new tasks
Failure: Rollback to previous version
```

---

## Monitoring & Troubleshooting

### View Logs

**Via AWS Console**:
1. Go to: CloudWatch → Log groups → `/ecs/frontend-dev`
2. Select log stream
3. View container logs

**Via AWS CLI**:
```bash
# Get recent logs
aws logs tail /ecs/frontend-dev --follow
```

### Check Service Health

```bash
# Get service status
aws ecs describe-services \
  --cluster angular-app-dev \
  --services frontend-service-dev

# Get running tasks
aws ecs list-tasks \
  --cluster angular-app-dev \
  --service-name frontend-service-dev

# Describe task
aws ecs describe-tasks \
  --cluster angular-app-dev \
  --tasks TASK_ARN_HERE
```

### Common Issues

**Issue 1: Tasks keep stopping**
- Check CloudWatch logs for errors
- Verify health check configuration
- Ensure container port 80 is exposed

**Issue 2: Load balancer health check failing**
- Verify target group health check path (`/`)
- Check security group allows traffic from ALB
- Ensure container is responding on port 80

**Issue 3: Image pull error**
- Verify ECR repository exists
- Check IAM role has ECR pull permissions
- Ensure image tag exists in ECR

---

## Cost Management

### Monthly Cost Breakdown (per environment)

| Resource | Cost | Notes |
|----------|------|-------|
| **Fargate vCPU** | ~$10/month | 0.25 vCPU × 730 hours × $0.04048 |
| **Fargate Memory** | ~$5/month | 0.5 GB × 730 hours × $0.004445 |
| **Application Load Balancer** | ~$16/month | $0.0225/hour × 730 hours |
| **Data Transfer** | ~$0.50/month | Minimal for frontend |
| **ECR Storage** | < $0.10/month | < 500MB free tier |
| **CloudWatch Logs** | < $1/month | Free tier eligible |
| **TOTAL per environment** | **~$32/month** | |

### Cost Optimization Strategies

1. **Use Shared ALB** for dev/qa (save ~$16/month)
2. **Stop non-production services** when not in use
3. **Use Fargate Spot** for dev/qa (70% cheaper, may interrupt)
4. **Reduce task count** to 0 when not needed
5. **Set up auto-scaling** to scale down during off-hours

### Cost Savings Commands

```bash
# Stop development service (set desired count to 0)
aws ecs update-service \
  --cluster angular-app-dev \
  --service frontend-service-dev \
  --desired-count 0

# Restart when needed
aws ecs update-service \
  --cluster angular-app-dev \
  --service frontend-service-dev \
  --desired-count 1
```

---

## Cleanup Instructions

### When You're Done Testing

**Complete teardown** (frees all resources):

```bash
#!/bin/bash

ENVIRONMENTS=("dev" "qa" "staging" "prod")

for ENV in "${ENVIRONMENTS[@]}"; do
  echo "Cleaning up $ENV environment..."

  # Delete ECS service
  aws ecs update-service \
    --cluster angular-app-$ENV \
    --service frontend-service-$ENV \
    --desired-count 0

  aws ecs delete-service \
    --cluster angular-app-$ENV \
    --service frontend-service-$ENV \
    --force

  # Delete ECS cluster
  aws ecs delete-cluster \
    --cluster angular-app-$ENV

  # Delete target group
  TG_ARN=$(aws elbv2 describe-target-groups \
    --names frontend-tg-$ENV \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

  aws elbv2 delete-target-group --target-group-arn $TG_ARN

  # Delete load balancer
  ALB_ARN=$(aws elbv2 describe-load-balancers \
    --names frontend-alb-$ENV \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text)

  aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN

  # Delete log group
  aws logs delete-log-group --log-group-name /ecs/frontend-$ENV
done

# Delete ECR repository (with all images)
aws ecr delete-repository \
  --repository-name angular-frontend \
  --force

echo "Cleanup complete! All resources deleted."
```

**Cost after cleanup**: $0/month ✅

---

## Summary

### What You've Created

✅ GitHub Actions workflow for ECS deployment
✅ Task definitions for 4 environments
✅ Complete setup instructions
✅ Cost management strategies
✅ Cleanup scripts

### Ready to Deploy When You:

1. Set up AWS resources (ECR, ECS, ALB)
2. Update task definitions with your account ID
3. Update workflow with ALB URLs
4. Push to GitHub

**Estimated setup time**: 2-3 hours
**Cost**: ~$32/month per environment (or ~$1-2 for 1-day test)

### Next Steps

**Option 1: Test ECS Now**
- Follow setup guide
- Deploy to development only
- Test for 1 day
- Tear down ($1-2 cost)

**Option 2: Complete Docker Locally First**
- Add backend Docker
- Full-stack docker-compose
- Then test ECS

**Option 3: Skip ECS**
- Continue with serverless (S3 + Lambda)
- Keep ECS workflow as reference

Your choice! 🚀
