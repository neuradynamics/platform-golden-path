#!/usr/bin/env python3
"""
Simple script to export Infisical secrets to a .env file
"""

import argparse
import os

from dotenv import load_dotenv
from infisical_sdk import InfisicalSDKClient


def main():
    load_dotenv()

    # Get credentials from environment variables
    infisical_url = os.getenv("INFISICAL_URL", "https://app.infisical.com/api")
    client_id = os.getenv("INFISICAL_CLIENT_ID")
    client_secret = os.getenv("INFISICAL_CLIENT_SECRET")
    workspace_id = os.getenv("INFISICAL_WORKSPACE_ID")

    if not client_id or not client_secret or not workspace_id:
        print("Error: Missing required environment variables.")
        print(
            "Please ensure INFISICAL_CLIENT_ID, INFISICAL_CLIENT_SECRET, and INFISICAL_WORKSPACE_ID are set in your .env file."
        )
        exit(1)

    parser = argparse.ArgumentParser(
        description="Export Infisical secrets to .env file"
    )
    parser.add_argument(
        "--environment", default="dev", help="Environment slug (default: Development)"
    )
    parser.add_argument(
        "--path", default="/backend", help="Secret path (default: /backend)"
    )
    parser.add_argument(
        "--output", default=".env", help="Output file path (default: .env)"
    )

    args = parser.parse_args()

    host = infisical_url.replace("/api", "")

    print(f"Fetching secrets from {args.environment} environment, path {args.path}...")

    try:
        # Initialize the client
        client = InfisicalSDKClient(host=host)

        # Authenticate using Universal Auth
        client.auth.universal_auth.login(
            client_id=client_id, client_secret=client_secret
        )

        # Fetch secrets
        secrets_response = client.secrets.list_secrets(
            project_id=workspace_id,
            environment_slug=args.environment,
            secret_path=args.path,
            recursive=True,
            include_imports=True,
        )

        # Write secrets to .env file
        with open(args.output, "w") as f:
            f.write(f'INFISICAL_URL="{infisical_url}"\n')
            f.write(f"INFISICAL_CLIENT_ID='{client_id}'\n")
            f.write(f"INFISICAL_CLIENT_SECRET='{client_secret}'\n")
            f.write(f"INFISICAL_WORKSPACE_ID='{workspace_id}'\n\n")

            for secret in secrets_response.secrets:
                value = secret.secretValue.replace('"', '\\"')
                f.write(f'{secret.secretKey}="{value}"\n')

        print(
            f"Successfully saved {len(secrets_response.secrets)} secrets to {args.output}"
        )

    except Exception as e:
        print(f"Error: {str(e)}")
        exit(1)


if __name__ == "__main__":
    main()