#!/bin/bash
set -e

echo "=== Updating Kubernetes Image Tags ==="

# Get release tag from environment variable or parameter
if [ -n "$NEW_RELEASE_TAG" ]; then
  RELEASE_TAG="$NEW_RELEASE_TAG"
  echo "Using environment variable: $RELEASE_TAG"
elif [ -n "$1" ]; then
  RELEASE_TAG="$1"
  echo "Using command line argument: $RELEASE_TAG"
else
  echo "Error: No release tag provided"
  echo "Usage: NEW_RELEASE_TAG=<tag> $0 OR $0 <tag>"
  exit 1
fi

# Define container registry and image configurations
CONTAINER_REGISTRY="${CONTAINER_REGISTRY:-<YOUR_REGISTRY>.azurecr.io}"
K8S_MANIFESTS_PATH="${K8S_MANIFESTS_PATH:-infrastructure/k8s/staging}"

echo "=== Updating image tags to '$RELEASE_TAG' ==="

# Check if manifests directory exists
if [ ! -d "$K8S_MANIFESTS_PATH" ]; then
  echo "Error: Kubernetes manifests directory not found: $K8S_MANIFESTS_PATH"
  exit 1
fi

cd "$K8S_MANIFESTS_PATH"

# Update FastAPI backend image
if [ -f "backend-deployment.yaml" ]; then
  sed -i "s|${CONTAINER_REGISTRY}/backend-fastapi:.*|${CONTAINER_REGISTRY}/backend-fastapi:${RELEASE_TAG}|g" backend-deployment.yaml
  echo "Updated FastAPI backend image tag"
fi

# Update any additional service images here
# Example: Update other microservices
# sed -i "s|${CONTAINER_REGISTRY}/service-name:.*|${CONTAINER_REGISTRY}/service-name:${RELEASE_TAG}|g" service-deployment.yaml

echo "=== Updated image tags to $RELEASE_TAG ==="

# Show the updated images
echo "=== Current image configurations ==="
if [ -f "backend-deployment.yaml" ]; then
  echo "Backend images:"
  grep -E "^\s*image:" backend-deployment.yaml || echo "No images found in backend-deployment.yaml"
fi

echo "Image tag update completed successfully" 