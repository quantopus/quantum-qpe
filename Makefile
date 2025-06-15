.PHONY: help install test lint format build clean dev-install venv venv-clean
.DEFAULT_GOAL := help

# Python virtual environment settings
VENV_NAME ?= .venv
PYTHON ?= python3
PIP = $(VENV_NAME)/bin/pip
PYTHON_VENV = $(VENV_NAME)/bin/python

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

venv: ## Create virtual environment
	$(PYTHON) -m venv $(VENV_NAME)
	$(PIP) install --upgrade pip setuptools wheel
	@echo "Virtual environment created. Activate with: source $(VENV_NAME)/bin/activate"

venv-clean: ## Remove virtual environment
	rm -rf $(VENV_NAME)

install: venv ## Install package in virtual environment
	$(PIP) install -e .

dev-install: venv ## Install with development dependencies in virtual environment
	$(PIP) install -e ".[dev,test]"

test: ## Run tests
	@if [ -f "$(PYTHON_VENV)" ]; then $(PYTHON_VENV) -m pytest tests/; else pytest tests/; fi

test-cov: ## Run tests with coverage
	@if [ -f "$(PYTHON_VENV)" ]; then $(PYTHON_VENV) -m pytest --cov=quantum_qpe --cov-report=html tests/; else pytest --cov=quantum_qpe --cov-report=html tests/; fi

lint: ## Run linter
	@if [ -f "$(PYTHON_VENV)" ]; then $(PYTHON_VENV) -m ruff check src tests && $(PYTHON_VENV) -m mypy src; else ruff check src tests && mypy src; fi

format: ## Format code
	@if [ -f "$(PYTHON_VENV)" ]; then $(PYTHON_VENV) -m black src tests && $(PYTHON_VENV) -m ruff check --fix src tests; else black src tests && ruff check --fix src tests; fi

build: ## Build package
	@if [ -f "$(PYTHON_VENV)" ]; then $(PYTHON_VENV) -m build; else python -m build; fi

clean: ## Clean build artifacts
	rm -rf build/ dist/ *.egg-info/ htmlcov/ .coverage .pytest_cache/
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete

clean-all: clean venv-clean ## Clean everything including virtual environment

git-setup: ## Setup git repository
	git init
	git add .
	git commit -m "Initial quantum-qpe v0.1.0"
	git branch -M main
	git remote add origin https://github.com/quantopus/quantum-qpe.git
	@echo "Run: git push -u origin main"

release: ## Create release tag
	git tag v0.1.0
	@echo "Run: git push --tags"

demo: ## Run QPE demo
	@if [ -f "$(PYTHON_VENV)" ]; then $(PYTHON_VENV) -c "from quantum_qpe.main import QPEAlgorithm, QPEParams; qpe = QPEAlgorithm(); params = QPEParams(angle=0.25, unitary='rotation', precision=4); print(qpe.execute(params))"; else python -c "from quantum_qpe.main import QPEAlgorithm, QPEParams; qpe = QPEAlgorithm(); params = QPEParams(angle=0.25, unitary='rotation', precision=4); print(qpe.execute(params))"; fi

hatch-test: ## Run tests using hatch (if available)
	@if command -v hatch >/dev/null 2>&1; then hatch run test; else echo "Hatch not available, use 'make test'"; fi 