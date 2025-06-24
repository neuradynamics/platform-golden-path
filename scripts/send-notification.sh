#!/bin/bash
set -e

echo "=== Sending Pipeline Notification ==="

# Function to display usage
usage() {
  echo "Usage: $0 <STATUS> <MESSAGE> <WEBHOOK_URL> <CONTEXT>"
  echo "  STATUS: SUCCESS or FAILURE"
  echo "  MESSAGE: Notification message"
  echo "  WEBHOOK_URL: Teams/Slack webhook URL"
  echo "  CONTEXT: Context like RELEASE_TAG, DOCKER_BUILD, KUBERNETES_DEPLOY, etc."
  exit 1
}

# Check parameters
if [ $# -lt 4 ]; then
  echo "Error: Missing required parameters"
  usage
fi

STATUS="$1"
MESSAGE="$2"
WEBHOOK_URL="$3"
CONTEXT="$4"

# Validate status
if [ "$STATUS" != "SUCCESS" ] && [ "$STATUS" != "FAILURE" ]; then
  echo "Error: STATUS must be either 'SUCCESS' or 'FAILURE'"
  exit 1
fi

# Set status-specific properties
if [ "$STATUS" = "SUCCESS" ]; then
  ICON="✅"
  COLOR="#00FF00"
  THEME_COLOR="good"
else
  ICON="❌"
  COLOR="#FF0000"
  THEME_COLOR="danger"
fi

# Get pipeline information
BUILD_ID="${BUILD_BUILDID:-unknown}"
PIPELINE_URL="${SYSTEM_COLLECTIONURI:-}${SYSTEM_TEAMPROJECT:-}/_build/results?buildId=$BUILD_ID"
SOURCE_BRANCH="${BUILD_SOURCEBRANCH:-unknown}"
BUILD_REASON="${BUILD_REASON:-unknown}"

# Create notification payload for Microsoft Teams
TEAMS_PAYLOAD=$(cat <<EOF
{
  "cards": [
    {
      "header": {
        "title": "$ICON Pipeline $STATUS - $CONTEXT",
        "subtitle": "$MESSAGE"
      },
      "sections": [
        {
          "widgets": [
            {
              "keyValue": {
                "topLabel": "Build ID",
                "content": "$BUILD_ID"
              }
            },
            {
              "keyValue": {
                "topLabel": "Source Branch",
                "content": "$SOURCE_BRANCH"
              }
            },
            {
              "keyValue": {
                "topLabel": "Build Reason",
                "content": "$BUILD_REASON"
              }
            },
            {
              "buttons": [
                {
                  "textButton": {
                    "text": "View Pipeline",
                    "onClick": {
                      "openLink": {
                        "url": "$PIPELINE_URL"
                      }
                    }
                  }
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
EOF
)

# Send notification
echo "Sending notification to webhook..."
if curl --location --request POST "$WEBHOOK_URL" \
     --header "Content-Type: application/json" \
     --data-raw "$TEAMS_PAYLOAD" \
     --silent --show-error --fail; then
  echo "✅ Notification sent successfully"
else
  echo "❌ Failed to send notification"
  exit 1
fi 