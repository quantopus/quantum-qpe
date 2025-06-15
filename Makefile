.PHONY: help install test lint format build clean dev-install venv venv-clean ensure-venv check-venv
.DEFAULT_GOAL := help

# Python virtual environment settings
VENV_NAME ?= .venv
PYTHON ?= python3
PIP = $(VENV_NAME)/bin/pip
PYTHON_VENV = $(VENV_NAME)/bin/python

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Check if virtual environment exists and is properly set up
check-venv:
	@if [ ! -f "$(PYTHON_VENV)" ]; then \
		echo "$(RED)❌ Virtual environment not found at $(VENV_NAME)$(NC)"; \
		echo "$(YELLOW)🔧 Creating virtual environment...$(NC)"; \
		$(MAKE) venv; \
	else \
		echo "$(GREEN)✅ Virtual environment found$(NC)"; \
	fi

# Ensure virtual environment exists and dependencies are installed
ensure-venv: check-venv
	@if [ ! -f "$(VENV_NAME)/lib/python*/site-packages/pennylane/__init__.py" ] && [ ! -f "$(VENV_NAME)/lib/python*/site-packages/PennyLane-*.dist-info" ]; then \
		echo "$(YELLOW)📦 Installing dependencies...$(NC)"; \
		$(PIP) install -e ".[dev,test]"; \
	else \
		echo "$(GREEN)✅ Dependencies already installed$(NC)"; \
	fi

help: ## Show this help message
	@echo "$(GREEN)🚀 Quantum QPE Makefile Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)💡 All commands automatically use virtual environment!$(NC)"

venv: ## Create virtual environment
	@echo "$(YELLOW)🏗️  Creating virtual environment...$(NC)"
	$(PYTHON) -m venv $(VENV_NAME)
	$(PIP) install --upgrade pip setuptools wheel
	@echo "$(GREEN)✅ Virtual environment created at $(VENV_NAME)$(NC)"

venv-clean: ## Remove virtual environment
	@echo "$(YELLOW)🧹 Removing virtual environment...$(NC)"
	rm -rf $(VENV_NAME)
	@echo "$(GREEN)✅ Virtual environment removed$(NC)"

install: ensure-venv ## Install package with dependencies
	@echo "$(YELLOW)📦 Installing package...$(NC)"
	$(PIP) install -e .
	@echo "$(GREEN)✅ Package installed$(NC)"

dev-install: ensure-venv ## Install with development dependencies  
	@echo "$(YELLOW)📦 Installing package with dev dependencies...$(NC)"
	$(PIP) install -e ".[dev,test]"
	@echo "$(GREEN)✅ Development environment ready$(NC)"

test: ensure-venv ## Run tests
	@echo "$(YELLOW)🧪 Running tests...$(NC)"
	$(PYTHON_VENV) -m pytest tests/
	@echo "$(GREEN)✅ Tests completed$(NC)"

test-cov: ensure-venv ## Run tests with coverage
	@echo "$(YELLOW)🧪 Running tests with coverage...$(NC)"
	$(PYTHON_VENV) -m pytest --cov=quantum_qpe --cov-report=html tests/
	@echo "$(GREEN)✅ Tests with coverage completed$(NC)"
	@echo "$(YELLOW)📊 Coverage report available at: htmlcov/index.html$(NC)"

lint: ensure-venv ## Run linter
	@echo "$(YELLOW)🔍 Running linter...$(NC)"
	$(PYTHON_VENV) -m ruff check src tests
	$(PYTHON_VENV) -m mypy src
	@echo "$(GREEN)✅ Linting completed$(NC)"

format: ensure-venv ## Format code
	@echo "$(YELLOW)✨ Formatting code...$(NC)"
	$(PYTHON_VENV) -m black src tests
	$(PYTHON_VENV) -m ruff check --fix src tests
	@echo "$(GREEN)✅ Code formatting completed$(NC)"

build: ensure-venv ## Build package
	@echo "$(YELLOW)🏗️  Building package...$(NC)"
	$(PYTHON_VENV) -m build
	@echo "$(GREEN)✅ Package built$(NC)"

clean: ## Clean build artifacts
	@echo "$(YELLOW)🧹 Cleaning build artifacts...$(NC)"
	rm -rf build/ dist/ *.egg-info/ htmlcov/ .coverage .pytest_cache/
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	@echo "$(GREEN)✅ Clean completed$(NC)"

clean-all: clean venv-clean ## Clean everything including virtual environment
	@echo "$(GREEN)✅ Everything cleaned$(NC)"

# Project version (now uses virtual environment)
project-version: ensure-venv ## Show project version
	@$(PYTHON_VENV) -c "from src.quantum_qpe import __version__; print('Project version:', __version__)"

git-setup: ## Setup git repository
	git init
	git add .
	git commit -m "Initial quantum-qpe v0.1.0"
	git branch -M main
	git remote add origin https://github.com/quantopus/quantum-qpe.git
	@echo "$(YELLOW)📝 Run: git push -u origin main$(NC)"

release: project-version ## Create release tag
	@$(eval PROJECT_VERSION := $(shell $(PYTHON_VENV) -c "from src.quantum_qpe import __version__; print(__version__)"))
	git tag v$(PROJECT_VERSION)
	@echo "$(YELLOW)📝 Run: git push --tags$(NC)"

demo: ensure-venv ## Run QPE demo
	@echo "$(YELLOW)🎯 Running QPE demo...$(NC)"
	$(PYTHON_VENV) -c "from quantum_qpe.main import QPEAlgorithm, QPEParams; qpe = QPEAlgorithm(); params = QPEParams(angle=0.25, unitary='rotation', precision=4); print('$(GREEN)🎉 Demo result:$(NC)'); print(qpe.execute(params))"

# New convenience commands
shell: ensure-venv ## Start shell with virtual environment activated
	@echo "$(GREEN)🐚 Starting shell with virtual environment...$(NC)"
	@echo "$(YELLOW)💡 Virtual environment is activated. Type 'exit' to return.$(NC)"
	@bash --init-file <(echo "source $(VENV_NAME)/bin/activate; echo '$(GREEN)✅ Virtual environment activated$(NC)'")

python: ensure-venv ## Start Python REPL with virtual environment
	@echo "$(GREEN)🐍 Starting Python with virtual environment...$(NC)"
	$(PYTHON_VENV)

jupyter: ensure-venv ## Start Jupyter notebook (if available)
	@echo "$(YELLOW)📓 Starting Jupyter notebook...$(NC)"
	@if $(PIP) list | grep -q jupyter; then \
		$(PYTHON_VENV) -m jupyter notebook; \
	else \
		echo "$(YELLOW)📦 Installing Jupyter...$(NC)"; \
		$(PIP) install jupyter; \
		$(PYTHON_VENV) -m jupyter notebook; \
	fi

status: ## Show environment status
	@echo "$(GREEN)📊 Environment Status$(NC)"
	@echo "$(YELLOW)Project Directory:$(NC) $(PWD)"
	@echo "$(YELLOW)Virtual Environment:$(NC) $(VENV_NAME)"
	@if [ -f "$(PYTHON_VENV)" ]; then \
		echo "$(GREEN)✅ Virtual Environment: Active$(NC)"; \
		echo "$(YELLOW)Python Version:$(NC) $$($(PYTHON_VENV) --version)"; \
		echo "$(YELLOW)Python Path:$(NC) $(PYTHON_VENV)"; \
		echo "$(YELLOW)Installed Packages:$(NC)"; \
		$(PIP) list | grep -E "(pennylane|quantum|numpy|pydantic)" || echo "  No quantum packages found"; \
	else \
		echo "$(RED)❌ Virtual Environment: Not found$(NC)"; \
	fi

# Hatch integration (with automatic venv fallback)
hatch-test: ## Run tests using hatch (with venv fallback)
	@if command -v hatch >/dev/null 2>&1; then \
		echo "$(YELLOW)🧪 Running tests with Hatch...$(NC)"; \
		hatch run test; \
	else \
		echo "$(YELLOW)⚠️  Hatch not available, using virtual environment...$(NC)"; \
		$(MAKE) test; \
	fi 