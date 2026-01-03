#!/bin/bash

# ============================================================================
# AWS ECS Setup Helper Script
# ============================================================================
#
# PURPOSE: Automated setup of AWS ECS resources for all environments
# USAGE: ./setup-ecs.sh
#
# REQUIREMENTS:
# - AWS CLI installed and configured
# - Appropriate IAM permissions
# - Docker installed (for testing)
#
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="us-east-1"
ECR_REPO="angular-frontend"
ENVIRONMENTS=("dev" "qa" "staging" "prod")

# ============================================================================
# Helper Functions
# ============================================================================

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    print_step "Checking prerequisites..."

    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Install it first: brew install awscli"
        exit 1
    fi

    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Run: aws configure"
        exit 1
    fi

    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    print_info "AWS Account ID: $ACCOUNT_ID"
    print_info "AWS Region: $AWS_REGION"
}

create_ecr_repository() {
    print_step "Creating ECR repository..."

    if aws ecr describe-repositories --repository-names $ECR_REPO --region $AWS_REGION &> /dev/null; then
        print_info "ECR repository already exists"
    else
        aws ecr create-repository \
            --repository-name $ECR_REPO \
            --region $AWS_REGION \
            --image-scanning-configuration scanOnPush=true

        print_info "ECR repository created successfully"
    fi

    ECR_URI=$(aws ecr describe-repositories \
        --repository-names $ECR_REPO \
        --region $AWS_REGION \
        --query 'repositories[0].repositoryUri' \
        --output text)

    print_info "ECR URI: $ECR_URI"
}

create_log_groups() {
    print_step "Creating CloudWatch log groups..."

    for env in "${ENVIRONMENTS[@]}"; do
        LOG_GROUP="/ecs/frontend-$env"

        if aws logs describe-log-groups --log-group-name-prefix $LOG_GROUP --region $AWS_REGION | grep -q $LOG_GROUP; then
            print_info "Log group $LOG_GROUP already exists"
        else
            aws logs create-log-group \
                --log-group-name $LOG_GROUP \
                --region $AWS_REGION

            print_info "Created log group: $LOG_GROUP"
        fi
    done
}

create_ecs_clusters() {
    print_step "Creating ECS clusters..."

    for env in "${ENVIRONMENTS[@]}"; do
        CLUSTER_NAME="angular-app-$env"

        if aws ecs describe-clusters --clusters $CLUSTER_NAME --region $AWS_REGION | grep -q "ACTIVE"; then
            print_info "Cluster $CLUSTER_NAME already exists"
        else
            aws ecs create-cluster \
                --cluster-name $CLUSTER_NAME \
                --region $AWS_REGION

            print_info "Created cluster: $CLUSTER_NAME"
        fi
    done
}

update_task_definitions() {
    print_step "Updating task definition files..."

    cd .aws

    for env in "${ENVIRONMENTS[@]}"; do
        FILE="task-definition-$env.json"

        if [ -f "$FILE" ]; then
            # Replace placeholder with actual account ID
            sed -i.bak "s/YOUR_ACCOUNT_ID/$ACCOUNT_ID/g" "$FILE"
            rm -f "$FILE.bak"

            print_info "Updated $FILE"
        else
            print_error "Task definition file not found: $FILE"
        fi
    done

    cd ..
}

print_next_steps() {
    print_step "Setup Complete!"

    echo ""
    echo "======================================================================"
    echo "                      NEXT STEPS"
    echo "======================================================================"
    echo ""
    echo "1. Create IAM Roles:"
    echo "   - ecsTaskExecutionRole"
    echo "   - ecsTaskRole"
    echo ""
    echo "2. Create Application Load Balancers (one per environment):"
    echo "   - frontend-alb-dev"
    echo "   - frontend-alb-qa"
    echo "   - frontend-alb-staging"
    echo "   - frontend-alb-prod"
    echo ""
    echo "3. Register Task Definitions:"
    for env in "${ENVIRONMENTS[@]}"; do
        echo "   aws ecs register-task-definition --cli-input-json file://.aws/task-definition-$env.json"
    done
    echo ""
    echo "4. Create ECS Services (connect to ALB)"
    echo ""
    echo "5. Update GitHub workflow with ALB URLs"
    echo ""
    echo "6. Push to GitHub to trigger deployment"
    echo ""
    echo "======================================================================"
    echo ""
    echo "See ECS-DEPLOYMENT-GUIDE.md for detailed instructions"
    echo ""
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    echo "======================================================================"
    echo "           AWS ECS Setup for Angular Frontend"
    echo "======================================================================"
    echo ""

    check_prerequisites
    create_ecr_repository
    create_log_groups
    create_ecs_clusters
    update_task_definitions
    print_next_steps
}

main
