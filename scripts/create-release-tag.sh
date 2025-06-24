#!/bin/bash
set -e  # Fail script on any error

echo "=== Creating Release Tag ==="

# Check if required environment variable is set
if [ -z "$SYSTEM_ACCESSTOKEN" ]; then
  echo "Error: SYSTEM_ACCESSTOKEN environment variable is not set"
  exit 1
fi

# Get the latest version tag
LATEST_TAG=$(git tag -l "[0-9]*.[0-9]*.[0-9]*" --sort=-v:refname | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$" | head -n1)

if [ -z "$LATEST_TAG" ]; then
  # No existing tags, start with initial version
  NEW_TAG="0.1.0"
  echo "No existing version found. Starting at $NEW_TAG"
else
  echo "Found latest version: $LATEST_TAG"

  # Split the version number into components
  IFS='.' read -ra VERSION_PARTS <<< "$LATEST_TAG"
  MAJOR=${VERSION_PARTS[0]}
  MINOR=${VERSION_PARTS[1]}
  PATCH=${VERSION_PARTS[2]}

  # Increment patch version
  PATCH=$((PATCH + 1))
  NEW_TAG="${MAJOR}.${MINOR}.${PATCH}"
  echo "Incrementing to $NEW_TAG"
fi

# Configure Git
git config user.name "Azure Pipeline Bot"
git config user.email "pipeline@company.com"

# Create and push tag with authentication
git tag -a "$NEW_TAG" -m "Release ${NEW_TAG} created by CI pipeline"
git config --global http.https://dev.azure.com/.extraheader "AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN"
git push origin "$NEW_TAG"

# Output variable for downstream tasks
echo "##vso[task.setvariable variable=NEW_RELEASE_TAG;isOutput=true]$NEW_TAG"
echo "Created new release: $NEW_TAG" 