# Root Makefile

.PHONY: push-backend sync-secrets install-uv

# Target to install uv (universal Python packager)
install-uv:
	@echo "Installing uv..."
	curl -LsSf https://astral.sh/uv/install.sh | sh
	@echo "uv installation script completed. Please ensure ~/.cargo/bin is in your PATH."
	@echo "You might need to source your shell profile (e.g., source ~/.bashrc) or open a new terminal."

# Target to push the backend
push-backend:
	@echo "Executing backend push..."
	$(MAKE) -C backend/fastapi push

# Target to sync secrets from Infisical for backend
sync-secrets:
	@echo "Syncing Infisical secrets..."
	@echo "Setting up Infisical sync script environment in ./scripts..."
	cd scripts && \
	uv venv --python python3 && \
	uv pip install infisical-sdk python-dotenv && \
	echo "Syncing backend secrets (environment: dev, Infisical path: /backend, output: backend/fastapi/.env)..." && \
	.venv/bin/python infisical_to_env.py --environment dev --path /backend --output ../backend/fastapi/.env
	@echo "Secrets sync complete." 