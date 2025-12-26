# Makefile for Docker Image Build System
# Provides convenient commands for building and managing the dev-environment image

.PHONY: help build build-no-cache build-pull tag push clean inspect run bash bash-root stop logs shell test

# Configuration
IMAGE_NAME ?= dev-environment
IMAGE_TAG ?= latest
DOCKERFILE ?= Dockerfile
BUILD_CONTEXT ?= .
# Container username (default from Dockerfile)
CONTAINER_USER := devuser
# Data directory for volume mounts (defaults to ~/dev-environment-data)
# Override with: make run DATA_DIR=/path/to/your/data
DATA_DIR ?= $(HOME)/dev-environment-data

# Full image name
FULL_IMAGE_NAME := $(IMAGE_NAME):$(IMAGE_TAG)

# Default target
.DEFAULT_GOAL := help

##@ Help

help: ## Display this help message
	@echo "Docker Image Build System"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*##"; printf "\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Building

build: ## Build the Docker image
	@echo "Building $(FULL_IMAGE_NAME)..."
	@docker build \
		-f $(DOCKERFILE) \
		-t $(FULL_IMAGE_NAME) \
		$(BUILD_CONTEXT)
	@echo "Build completed successfully!"
	@docker images $(IMAGE_NAME) --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

build-no-cache: ## Build the Docker image without using cache
	@echo "Building $(FULL_IMAGE_NAME) (no cache)..."
	@docker build \
		--no-cache \
		-f $(DOCKERFILE) \
		-t $(FULL_IMAGE_NAME) \
		$(BUILD_CONTEXT)
	@echo "Build completed successfully!"

build-pull: ## Build the Docker image with --pull flag
	@echo "Building $(FULL_IMAGE_NAME) (pulling base image)..."
	@docker build \
		--pull \
		-f $(DOCKERFILE) \
		-t $(FULL_IMAGE_NAME) \
		$(BUILD_CONTEXT)
	@echo "Build completed successfully!"

build-verbose: ## Build the Docker image with verbose output
	@echo "Building $(FULL_IMAGE_NAME) (verbose)..."
	@docker build \
		--progress=plain \
		-f $(DOCKERFILE) \
		-t $(FULL_IMAGE_NAME) \
		$(BUILD_CONTEXT)
	@echo "Build completed successfully!"

##@ Tagging

tag: ## Tag the image with a new tag (usage: make tag NEW_TAG=v1.0.0)
	@if [ -z "$(NEW_TAG)" ]; then \
		echo "Error: NEW_TAG is required. Usage: make tag NEW_TAG=v1.0.0"; \
		exit 1; \
	fi
	@echo "Tagging $(FULL_IMAGE_NAME) as $(IMAGE_NAME):$(NEW_TAG)..."
	@docker tag $(FULL_IMAGE_NAME) $(IMAGE_NAME):$(NEW_TAG)
	@echo "Tagged successfully!"

##@ Container Management

run: ## Run the container with SSH daemon (default - keeps container alive, usage: make run PORT=2222 SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)" DATA_DIR=~/my-data)
	@PORT=$${PORT:-2222}; \
	DATA_DIR=$${DATA_DIR:-$(HOME)/dev-environment-data}; \
	echo "Starting container with SSH daemon on port $$PORT..."; \
	echo "Using data directory: $$DATA_DIR"; \
	mkdir -p "$$DATA_DIR/workspace" "$$DATA_DIR/projects" "$$DATA_DIR/.claude" "$$DATA_DIR/.config" "$$DATA_DIR/.local" || true; \
	chmod -R 755 "$$DATA_DIR" 2>/dev/null || true; \
	docker rm -f dev-env 2>/dev/null || true; \
	if [ -n "$$SSH_PUBLIC_KEY" ]; then \
		docker run -d \
			-p $$PORT:22 \
			-e SSH_PUBLIC_KEY="$$SSH_PUBLIC_KEY" \
			-v "$$DATA_DIR/workspace:/home/$(CONTAINER_USER)/workspace" \
			-v "$$DATA_DIR/projects:/home/$(CONTAINER_USER)/projects" \
			-v "$$DATA_DIR/.claude:/home/$(CONTAINER_USER)/.claude" \
			-v "$$DATA_DIR/.claude.json:/home/$(CONTAINER_USER)/.claude.json" \
			-v "$$DATA_DIR/.config:/home/$(CONTAINER_USER)/.config" \
			-v "$$DATA_DIR/.local:/home/$(CONTAINER_USER)/.local" \
			--name dev-env \
			$(FULL_IMAGE_NAME); \
	else \
		docker run -d \
			-p $$PORT:22 \
			-v "$$DATA_DIR/workspace:/home/$(CONTAINER_USER)/workspace" \
			-v "$$DATA_DIR/projects:/home/$(CONTAINER_USER)/projects" \
			-v "$$DATA_DIR/.claude:/home/$(CONTAINER_USER)/.claude" \
			-v "$$DATA_DIR/.claude.json:/home/$(CONTAINER_USER)/.claude.json" \
			-v "$$DATA_DIR/.config:/home/$(CONTAINER_USER)/.config" \
			-v "$$DATA_DIR/.local:/home/$(CONTAINER_USER)/.local" \
			--name dev-env \
			$(FULL_IMAGE_NAME); \
	fi
	@echo "Container 'dev-env' is running!"
	@echo "Data directory: $${DATA_DIR:-$(HOME)/dev-environment-data}"
	@echo "SSH into it: ssh -p $${PORT:-2222} $(CONTAINER_USER)@localhost"

bash: ## Run the container interactively with bash (container exits when you exit)
	@echo "Starting interactive bash session as $(CONTAINER_USER)..."
	@docker run -it --rm \
		--name dev-env-interactive \
		$(FULL_IMAGE_NAME) bash

stop: ## Stop the running container
	@echo "Stopping container 'dev-env'..."
	@docker stop dev-env 2>/dev/null || echo "Container not running"
	@echo "Container stopped!"

logs: ## Show container logs
	@docker logs -f dev-env

shell: ## Get a shell in the running container
	@docker exec -it dev-env /bin/bash

bash-root: ## Run container interactively as root with bash prompt
	@echo "Starting interactive bash session as root..."
	@docker run -it --rm \
		--name dev-env-interactive \
		$(FULL_IMAGE_NAME) \
		/bin/bash

##@ Inspection

inspect: ## Inspect the Docker image
	@echo "Inspecting $(FULL_IMAGE_NAME)..."
	@docker inspect $(FULL_IMAGE_NAME)

size: ## Show image size
	@docker images $(IMAGE_NAME) --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

history: ## Show image build history
	@docker history $(FULL_IMAGE_NAME)

##@ Cleanup

clean: ## Remove the Docker image
	@echo "Removing image $(FULL_IMAGE_NAME)..."
	@docker rmi $(FULL_IMAGE_NAME) 2>/dev/null || echo "Image not found"
	@echo "Image removed!"

clean-all: clean ## Remove image and stop/remove container
	@echo "Stopping and removing container 'dev-env'..."
	@docker stop dev-env 2>/dev/null || true
	@docker rm dev-env 2>/dev/null || true
	@echo "Cleanup completed!"

##@ Testing

test: ## Run basic tests on the image
	@echo "Testing $(FULL_IMAGE_NAME)..."
	@echo "1. Checking if image exists..."
	@docker image inspect $(FULL_IMAGE_NAME) > /dev/null 2>&1 || (echo "Error: Image not found!" && exit 1)
	@echo "2. Testing container startup with SSH daemon..."
	@docker run --rm -d --name test-dev-env $(FULL_IMAGE_NAME) sshd > /dev/null 2>&1 || (echo "Error: Container failed to start!" && exit 1)
	@sleep 2
	@docker exec test-dev-env ps aux | grep -q sshd || (echo "Error: SSH daemon not running!" && docker rm -f test-dev-env && exit 1)
	@docker rm -f test-dev-env > /dev/null 2>&1
	@echo "All tests passed!"

