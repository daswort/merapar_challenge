PYTHON ?= .venv/bin/python
PIP ?= $(PYTHON) -m pip
APP_MODULE ?= app.main:app
HOST ?= 127.0.0.1
PORT ?= 8000

.DEFAULT_GOAL := help

.PHONY: help venv install install-prod install-dev run dev test lint format check clean package deploy

help:
	@echo "Available targets:"
	@echo "  make venv      - Create virtual environment (.venv)"
	@echo "  make install   - Install production dependencies (requirements.txt)"
	@echo "  make install-prod - Install production dependencies (requirements.txt)"
	@echo "  make install-dev  - Install development dependencies (requirements-dev.txt)"
	@echo "  make run       - Run app with Uvicorn"
	@echo "  make dev       - Run app with reload (development)"
	@echo "  make test      - Run tests"
	@echo "  make lint      - Run ruff checks"
	@echo "  make format    - Format code with black"
	@echo "  make check     - Run lint and tests"
	@echo "  make clean     - Remove cache and build artifacts"
	@echo "  make package   - Build Lambda deployment ZIP"
	@echo "  make deploy    - Build package and run terraform plan"

venv:
	@if [ ! -d .venv ]; then python3 -m venv .venv; fi

install: install-prod

install-prod: venv
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt

install-dev: venv
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements-dev.txt

run:
	$(PYTHON) -m uvicorn $(APP_MODULE) --host $(HOST) --port $(PORT)

dev:
	$(PYTHON) -m uvicorn $(APP_MODULE) --reload --host $(HOST) --port $(PORT)

test:
	$(PYTHON) -m pytest

lint:
	$(PYTHON) -m ruff check .

format:
	$(PYTHON) -m black .

check: lint test

clean:
	find . -type d -name __pycache__ -prune -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	rm -rf .pytest_cache .ruff_cache .mypy_cache build/

package: clean
	mkdir -p build
	$(PIP) install -r requirements.txt -t build/
	cp -r app/* build/
	rm -rf build/__pycache__
	rm -f infra/aws/app.zip
	cd build && zip -r ../infra/aws/app.zip . -x '__pycache__/*'
	rm -rf build/

deploy: package
	cd infra/aws && terraform plan
