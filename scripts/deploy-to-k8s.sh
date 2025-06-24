#!/bin/bash
set -e

echo "=== Deploying to Kubernetes ==="

# Configuration variables
K8S_MANIFESTS_PATH="${K8S_MANIFESTS_PATH:-infrastructure/k8s/staging}"
NAMESPACE="${NAMESPACE:-default}"
DEPLOYMENT_TIMEOUT="${DEPLOYMENT_TIMEOUT:-300s}"

# Check if manifests directory exists
if [ ! -d "$K8S_MANIFESTS_PATH" ]; then
  echo "Error: Kubernetes manifests directory not found: $K8S_MANIFESTS_PATH"
  exit 1
fi

cd "$K8S_MANIFESTS_PATH"

# Apply namespace (if exists)
if [ -f "namespace.yaml" ]; then
  echo "Applying namespace..."
  kubectl apply -f namespace.yaml
fi

# Apply configmaps and secrets first
echo "Applying configurations..."
if ls *configmap*.yaml 1> /dev/null 2>&1; then
  kubectl apply -f *configmap*.yaml
fi

if ls *secret*.yaml 1> /dev/null 2>&1; then
  kubectl apply -f *secret*.yaml
fi

# Apply infrastructure components
echo "Applying infrastructure components..."
if ls *pv*.yaml 1> /dev/null 2>&1; then
  kubectl apply -f *pv*.yaml
fi

if ls *service*.yaml 1> /dev/null 2>&1; then
  kubectl apply -f *service*.yaml
fi

# Clean up old replica sets to prevent rollout issues
echo "Cleaning up old replica sets..."
kubectl get rs -n "$NAMESPACE" --no-headers | awk '$2==0 {print $1}' | xargs -r kubectl delete rs -n "$NAMESPACE" || true

# Apply deployments
echo "Applying deployments..."
if ls *deployment*.yaml 1> /dev/null 2>&1; then
  kubectl apply -f *deployment*.yaml
fi

# Apply ingress rules
if ls *ingress*.yaml 1> /dev/null 2>&1; then
  echo "Applying ingress rules..."
  kubectl apply -f *ingress*.yaml
fi

echo "=== Kubernetes deployment completed ==="
echo "Deployment manifests applied successfully" 