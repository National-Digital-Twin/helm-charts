#!/bin/bash

# Build and push test-message-pod image to ECR
# Usage: ./build-and-push.sh [version]
#
# For local development (no push):
#   docker build -t test-message-pod:local .
#   kind load docker-image test-message-pod:local --name kind

set -e

VERSION=${1:-1.0.0}
ECR_REGISTRY="Idhere.dkr.ecr.eu-west-2.amazonaws.com"
ECR_REPO="curl-kafka-tools"
IMAGE_NAME="test-message-pod"
FULL_IMAGE="${ECR_REGISTRY}/${ECR_REPO}:${VERSION}"

echo "Building ${IMAGE_NAME}:${VERSION}..."

# Navigate to the directory containing the Dockerfile
cd "$(dirname "$0")"

# Build the image
docker build -t ${IMAGE_NAME}:${VERSION} .

# Tag for ECR
docker tag ${IMAGE_NAME}:${VERSION} ${FULL_IMAGE}

echo "Authenticating with ECR..."
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin ${ECR_REGISTRY}

echo "Pushing ${FULL_IMAGE}..."
docker push ${FULL_IMAGE}

echo ""
echo "✅ Successfully built and pushed: ${FULL_IMAGE}"
echo ""
echo "To deploy with Helm:"
echo "  helm install test-msg . -n org-b --set image.tag=${VERSION}"
echo ""
echo "For local Kind development:"
echo "  docker build -t test-message-pod:local ."
echo "  kind load docker-image test-message-pod:local --name kind"
echo "  helm install test-msg . -n org-b -f values-local.yaml"
