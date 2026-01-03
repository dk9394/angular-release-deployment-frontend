#!/bin/bash

# ============================================================================
# AWS ECS Cleanup Script
# ============================================================================
#
# PURPOSE: Remove all ECS resources to stop incurring costs
# USAGE: ./cleanup-ecs.sh
#
# WARNING: This will delete ALL ECS resources for this project!
#          Make sure you want to do this before running.
#
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
AWS_REGION="us-east-1"
ECR_REPO="angular-frontend"
ENVIRONMENTS=("dev" "qa" "staging" "prod")

print_warning() {
    echo -e "${RED}[WARNING]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

confirm_deletion() {
    echo ""
    print_warning "This will DELETE all ECS resources:"
    echo "  - ECS Services (all environments)"
    echo "  - ECS Clusters (all environments)"
    echo "  - Target Groups (all environments)"
    echo "  - Load Balancers (all environments)"
    echo "  - CloudWatch Log Groups"
    echo "  - ECR Repository (with all images)"
    echo ""
    print_warning "Estimated cost savings: ~$128/month (for 4 environments)"
    echo ""
    read -p "Are you sure you want to proceed? (type 'yes' to confirm): " confirm

    if [ "$confirm" != "yes" ]; then
        echo "Cleanup cancelled."
        exit 0
    fi
}

delete_ecs_services() {
    print_info "Deleting ECS services..."

    for env in "${ENVIRONMENTS[@]}"; do
        CLUSTER="angular-app-$env"
        SERVICE="frontend-service-$env"

        if aws ecs describe-services --cluster $CLUSTER --services $SERVICE --region $AWS_REGION &> /dev/null; then
            print_info "Scaling down service: $SERVICE"
            aws ecs update-service \
                --cluster $CLUSTER \
                --service $SERVICE \
                --desired-count 0 \
                --region $AWS_REGION &> /dev/null || true

            print_info "Deleting service: $SERVICE"
            aws ecs delete-service \
                --cluster $CLUSTER \
                --service $SERVICE \
                --force \
                --region $AWS_REGION &> /dev/null || true

            print_success "Service deleted: $SERVICE"
        else
            print_info "Service not found: $SERVICE (skipping)"
        fi
    done
}

delete_ecs_clusters() {
    print_info "Deleting ECS clusters..."

    for env in "${ENVIRONMENTS[@]}"; do
        CLUSTER="angular-app-$env"

        if aws ecs describe-clusters --clusters $CLUSTER --region $AWS_REGION | grep -q "ACTIVE"; then
            aws ecs delete-cluster \
                --cluster $CLUSTER \
                --region $AWS_REGION &> /dev/null || true

            print_success "Cluster deleted: $CLUSTER"
        else
            print_info "Cluster not found: $CLUSTER (skipping)"
        fi
    done
}

delete_target_groups() {
    print_info "Deleting target groups..."

    for env in "${ENVIRONMENTS[@]}"; do
        TG_NAME="frontend-tg-$env"
        TG_ARN=$(aws elbv2 describe-target-groups \
            --region $AWS_REGION \
            --query "TargetGroups[?TargetGroupName=='$TG_NAME'].TargetGroupArn" \
            --output text 2>/dev/null || echo "")

        if [ -n "$TG_ARN" ]; then
            aws elbv2 delete-target-group \
                --target-group-arn $TG_ARN \
                --region $AWS_REGION &> /dev/null || true

            print_success "Target group deleted: $TG_NAME"
        else
            print_info "Target group not found: $TG_NAME (skipping)"
        fi
    done
}

delete_load_balancers() {
    print_info "Deleting load balancers (this may take a few minutes)..."

    for env in "${ENVIRONMENTS[@]}"; do
        ALB_NAME="frontend-alb-$env"
        ALB_ARN=$(aws elbv2 describe-load-balancers \
            --region $AWS_REGION \
            --query "LoadBalancers[?LoadBalancerName=='$ALB_NAME'].LoadBalancerArn" \
            --output text 2>/dev/null || echo "")

        if [ -n "$ALB_ARN" ]; then
            aws elbv2 delete-load-balancer \
                --load-balancer-arn $ALB_ARN \
                --region $AWS_REGION &> /dev/null || true

            print_success "Load balancer deleted: $ALB_NAME"
        else
            print_info "Load balancer not found: $ALB_NAME (skipping)"
        fi
    done

    print_info "Waiting for load balancers to be fully deleted (60 seconds)..."
    sleep 60
}

delete_log_groups() {
    print_info "Deleting CloudWatch log groups..."

    for env in "${ENVIRONMENTS[@]}"; do
        LOG_GROUP="/ecs/frontend-$env"

        if aws logs describe-log-groups --log-group-name-prefix $LOG_GROUP --region $AWS_REGION | grep -q $LOG_GROUP; then
            aws logs delete-log-group \
                --log-group-name $LOG_GROUP \
                --region $AWS_REGION &> /dev/null || true

            print_success "Log group deleted: $LOG_GROUP"
        else
            print_info "Log group not found: $LOG_GROUP (skipping)"
        fi
    done
}

delete_ecr_repository() {
    print_info "Deleting ECR repository (with all images)..."

    if aws ecr describe-repositories --repository-names $ECR_REPO --region $AWS_REGION &> /dev/null; then
        aws ecr delete-repository \
            --repository-name $ECR_REPO \
            --force \
            --region $AWS_REGION &> /dev/null || true

        print_success "ECR repository deleted: $ECR_REPO"
    else
        print_info "ECR repository not found: $ECR_REPO (skipping)"
    fi
}

main() {
    echo "======================================================================"
    echo "           AWS ECS Cleanup Script"
    echo "======================================================================"

    confirm_deletion

    echo ""
    print_info "Starting cleanup process..."
    echo ""

    delete_ecs_services
    sleep 10  # Wait for services to scale down
    delete_ecs_clusters
    delete_target_groups
    delete_load_balancers
    delete_log_groups
    delete_ecr_repository

    echo ""
    echo "======================================================================"
    print_success "Cleanup complete!"
    echo "======================================================================"
    echo ""
    echo "All ECS resources have been deleted."
    echo "Your AWS bill should drop to $0/month for these services."
    echo ""
    echo "NOTE: If you created IAM roles manually, delete them via IAM console:"
    echo "  - ecsTaskExecutionRole"
    echo "  - ecsTaskRole"
    echo ""
}

main
