# CI/CD Pipeline

## 1. Overview

Git Push
↓
GitHub Actions
↓
CI
├── Checkout
├── Node dependency validation
├── Docker Build
├── Terraform Init
├── Terraform Format
└── Terraform Validate
↓
CD
↓
Docker Image
↓
ECR
↓
ECS Deployment
↓
Health Verification

## 2. CI Workflow

## 3. Docker Build

## 4. ECR Image Publishing

## 5. ECS Deployment

## 6. Deployment Verification

## 7. Rollback Considerations

## 8. Security Considerations

## 9. Future Improvement: GitHub OIDC
