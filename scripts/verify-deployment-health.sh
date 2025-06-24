#!/bin/bash
set -e

echo "=== Verifying Deployment Health ==="

# Configuration variables
NAMESPACE="${NAMESPACE:-default}"
DEPLOYMENT_TIMEOUT="${DEPLOYMENT_TIMEOUT:-300s}"
HEALTH_CHECK_RETRIES="${HEALTH_CHECK_RETRIES:-5}"
HEALTH_CHECK_INTERVAL="${HEALTH_CHECK_INTERVAL:-30}"

# Function to check deployment status
check_deployment_status() {
  local deployment_name=$1
  local namespace=$2
  
  echo "Checking deployment: $deployment_name in namespace: $namespace"
  
  if ! kubectl rollout status deployment/"$deployment_name" -n "$namespace" --timeout="$DEPLOYMENT_TIMEOUT"; then
    echo "❌ Deployment $deployment_name failed to roll out"
    kubectl get pods -n "$namespace" -l app="$deployment_name"
    kubectl describe pods -n "$namespace" -l app="$deployment_name"
    return 1
  fi
  
  echo "✅ Deployment $deployment_name is healthy"
  return 0
}

# Function to check pod readiness
check_pod_readiness() {
  local app_label=$1
  local namespace=$2
  
  echo "Checking pod readiness for app: $app_label"
  
  local ready_pods=$(kubectl get pods -n "$namespace" -l app="$app_label" -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' | grep -o "True" | wc -l)
  local total_pods=$(kubectl get pods -n "$namespace" -l app="$app_label" --no-headers | wc -l)
  
  if [ "$ready_pods" -eq "$total_pods" ] && [ "$total_pods" -gt 0 ]; then
    echo "✅ All pods ready for $app_label ($ready_pods/$total_pods)"
    return 0
  else
    echo "❌ Not all pods ready for $app_label ($ready_pods/$total_pods)"
    return 1
  fi
}

# Get all deployments in the namespace
echo "Finding deployments in namespace: $NAMESPACE"
deployments=$(kubectl get deployments -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')

if [ -z "$deployments" ]; then
  echo "No deployments found in namespace: $NAMESPACE"
  exit 1
fi

# Check each deployment
deployment_failed=false
for deployment in $deployments; do
  if ! check_deployment_status "$deployment" "$NAMESPACE"; then
    deployment_failed=true
  fi
done

# Additional health checks
echo "=== Running additional health checks ==="

# Check service endpoints
echo "Checking service endpoints..."
services=$(kubectl get services -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')
for service in $services; do
  endpoints=$(kubectl get endpoints "$service" -n "$NAMESPACE" -o jsonpath='{.subsets[*].addresses[*].ip}' | wc -w)
  if [ "$endpoints" -gt 0 ]; then
    echo "✅ Service $service has $endpoints endpoint(s)"
  else
    echo "❌ Service $service has no endpoints"
    deployment_failed=true
  fi
done

# Final status
if [ "$deployment_failed" = true ]; then
  echo "=== Deployment Health Check FAILED ==="
  kubectl get pods -n "$NAMESPACE"
  kubectl get services -n "$NAMESPACE"
  exit 1
else
  echo "=== Deployment Health Check PASSED ==="
  echo "All deployments are healthy and ready"
  kubectl get pods -n "$NAMESPACE"
  kubectl get services -n "$NAMESPACE"
fi 