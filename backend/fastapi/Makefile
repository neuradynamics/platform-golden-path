# Makefile for Backend Local Development and CI Checks
#
# Usage:
#   - Run from the 'backend' directory.
#   - Assumes the following tools are installed and available in PATH:
#       uv, docker, docker-compose, bandit, safety, semgrep, jq
#   - Install Python dependencies with `uv sync` before running checks.
#
# Included Checks:
#   - Ruff: Code formatting and import sorting (compatible with Black/isort)
#   - Pylint: Linting (uses .pylintrc)
#   - Bandit, Safety, Semgrep: Security and static analysis
#
# Main Targets:
#   - make lint_check: Run code quality and formatting checks
#   - make security_checks: Run security analysis
#   - make all_check: Run all checks (default)
#   - make test: Build and test in Docker
#   - make docker_build: Build Docker containers
#   - make clean: Clean up Docker containers and images
#   - make install_dependencies: Install uv and sync dependencies
#   - make push: Run all checks, then push to remote

# Default target: run all checks (lint + security)
all_check: lint_check security_checks

# Linting and formatting checks
lint_check: ruff_check pylint_check

# Check code formatting with Ruff
ruff_check:
	@echo "Running Ruff format check..."
	uvx ruff format --check .
	uvx ruff check .

# Run pylint analysis (requires .pylintrc)
pylint_check:
	@echo "Running pylint analysis..."
	uv sync && uv run --active pylint --rcfile=.pylintrc --fail-under=8.5 app/

lint:
	@echo "Running Ruff format and fix"
	uvx ruff format .
	uvx ruff check . --fix
	
# Security checks: Bandit, Safety, Semgrep
security_checks: bandit_check semgrep_check safety_check

# Bandit: Python security linter
bandit_check:
	@echo "Running bandit security analysis..."
	uvx bandit -r app/ -f json -o reports/bandit-results.json || true
	@if [ -f reports/bandit-results.json ]; then \
		echo "Bandit security scan results generated: reports/bandit-results.json"; \
		echo "Summary (requires jq):"; \
		cat reports/bandit-results.json | jq '.results[] | {severity: .issue_severity, confidence: .issue_confidence, file: .filename, issue: .issue_text}' || echo "Note: jq not found or error parsing bandit-results.json. Raw JSON is available."; \
	else \
		echo "Bandit scan did not produce bandit-results.json (or command failed before report generation)."; \
	fi

# Safety: Dependency vulnerability checker
safety_check:
	@echo "Running safety dependency check..."
	@echo "Safety dependency scan results (console):"
	uvx safety check -r pyproject.toml --json

	@echo "Generating reports/safety-results.json..."
	uvx safety check -r pyproject.toml --json > reports/safety-results.json || true
	@if [ -f reports/safety-results.json ]; then \
		echo "Safety dependency scan JSON report generated: reports/safety-results.json"; \
	else \
		echo "Safety scan did not produce safety-results.json (or command failed before report generation)."; \
	fi

# Semgrep: Static code analysis
semgrep_check:
	@echo "Running semgrep code analysis..."
	uvx semgrep --config=p/python --output=reports/semgrep-results.json --json . || true
	@if [ -f reports/semgrep-results.json ]; then \
		echo "Semgrep code analysis results generated: reports/semgrep-results.json"; \
		echo "Summary (requires jq):"; \
		cat reports/semgrep-results.json | jq '.results[] | {severity: .extra.severity, rule: .check_id, file: .path, message: .extra.message}' || echo "Note: jq not found or error parsing semgrep-results.json. Raw JSON is available."; \
	else \
		echo "Semgrep scan did not produce semgrep-results.json (or command failed before report generation)."; \
	fi

# Install uv and sync dependencies
install_dependencies:
	curl -LsSf https://astral.sh/uv/install.sh | sh
	uv sync

# Build Docker containers (does not run tests)
docker_build:
	@echo "Building docker containers..."
	docker compose build

# Run tests in Docker (after building)
test: docker_build
	@echo "Running tests..."
	docker compose run --rm -e ENVIRONMENT=test \
		fastapi sh -c "set -e; uv run pytest -v --cov=app --cov-report=xml:/code/backend/reports/coverage.xml --cov-report=term --junitxml=/code/backend/reports/test-results.xml"

# Run tests in parallel (faster)
test-parallel: docker_build
	@echo "Running tests in parallel..."
	docker compose run --rm -e ENVIRONMENT=test \
		fastapi sh -c "set -e; uv run pytest -v -n auto --cov=app --cov-report=xml:/code/backend/reports/coverage.xml --cov-report=term --junitxml=/code/backend/reports/test-results.xml"

# Run tests with specific number of workers
test-parallel-workers: docker_build
	@echo "Running tests with $(WORKERS) workers..."
	docker compose run --rm -e ENVIRONMENT=test \
		fastapi sh -c "set -e; uv run pytest -v -n $(WORKERS) --cov=app --cov-report=xml:/code/backend/reports/coverage.xml --cov-report=term --junitxml=/code/backend/reports/test-results.xml"

# Push to remote after all checks pass
.PHONY: push
push: all_check
	@echo "All checks passed successfully."
	@echo "Proceeding to push to remote origin..."
	git push origin

# Clean up Docker containers and images
clean:
	@echo "Cleaning up docker containers and images..."
	docker compose down
