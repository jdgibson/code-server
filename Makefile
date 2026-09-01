.PHONY: help start stop status logs restart clean

# ============================================================================
# Code Server - Docker Swarm Makefile
# Manages deployment and lifecycle of the code-server services
# ============================================================================

# Default target
.DEFAULT_GOAL := help

# Service configuration
SUBSYSTEM_STACK := subsystem-code-server
SUBSYSTEM_COMPOSE := docker-compose.yml
SUBSYSTEM_HOST := docker-nuc
SUBSYSTEM_SERVICE := $(SUBSYSTEM_STACK)_subsystem-code-server

DEV_CONTAINER := code-server-dev
DEV_IMAGE := lscr.io/linuxserver/code-server:latest
DEV_PORT := 8008
DEV_COMPOSE := docker-compose.yml

CURRENT_DIR := $(shell pwd)

# Color output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m

# ============================================================================
# HELP
# ============================================================================

help:
	@echo "$(BLUE)Code Server - Docker Management$(NC)"
	@echo "$(YELLOW)Running 'make' without a target shows this list.$(NC)"
	@echo ""
	@echo "$(YELLOW)Usage:$(NC)"
	@echo "  make <target>"
	@echo ""
	@echo "$(YELLOW)Targets:$(NC)"
	@echo "  $(GREEN)start-subsystem$(NC)        Deploy the subsystem stack on docker-nuc"
	@echo "  $(GREEN)stop-subsystem$(NC)         Stop and remove the subsystem stack"
	@echo "  $(GREEN)status-subsystem$(NC)       Show subsystem stack services"
	@echo "  $(GREEN)logs-subsystem$(NC)         Follow subsystem container logs"
	@echo "  $(GREEN)restart-subsystem$(NC)      Restart the subsystem stack"
	@echo ""
	@echo "  $(GREEN)start-dev$(NC)              Start the local development container"
	@echo "  $(GREEN)stop-dev$(NC)               Stop the local development container"
	@echo "  $(GREEN)logs-dev$(NC)               Follow local development container logs"
	@echo "  $(GREEN)restart-dev$(NC)            Restart the local development container"
	@echo ""
	@echo "  $(GREEN)network-create$(NC)         Create the traefik network (one-time setup)"
	@echo "  $(GREEN)clean$(NC)                  Prune unused Docker resources"
	@echo "  $(GREEN)help$(NC)                   Show this help message"
	@echo ""
	@echo "$(YELLOW)Important Notes:$(NC)"
	@echo "  • Subsystem commands should be run ON docker-nuc"
	@echo "  • Local dev runs on localhost:$(DEV_PORT)"
	@echo "  • The traefik network must exist before deploying stacks (run network-create)"

# ============================================================================
# NETWORK SETUP
# ============================================================================

network-create:
	@echo "$(BLUE)Creating traefik network (if it doesn't exist)...$(NC)"
	docker network create traefik 2>/dev/null || echo "$(YELLOW)Network 'traefik' already exists$(NC)"
	@echo "$(GREEN)✓ Network ready$(NC)"

# ============================================================================
# SUBSYSTEM DEPLOYMENT (docker-nuc)
# ============================================================================

start-subsystem: network-create
	@echo "$(BLUE)Deploying subsystem-code-server stack...$(NC)"
	@echo "$(YELLOW)⚠ This command should be run ON docker-nuc$(NC)"
	docker stack deploy --detach=false --resolve-image always -c $(SUBSYSTEM_COMPOSE) $(SUBSYSTEM_STACK)
	@echo "$(GREEN)✓ Stack deployed$(NC)"
	@echo "$(YELLOW)View status with: make status-subsystem$(NC)"
	@echo "$(YELLOW)Code-server is available at: https://subsystem.mmto.arizona.edu/code-server/$(NC)"

stop-subsystem:
	@echo "$(BLUE)Stopping and removing subsystem-code-server stack...$(NC)"
	@echo "$(YELLOW)⚠ This command should be run ON docker-nuc$(NC)"
	@if docker stack ls --format '{{.Name}}' | grep -Fxq "$(SUBSYSTEM_STACK)"; then \
		docker stack rm $(SUBSYSTEM_STACK); \
		echo "$(GREEN)✓ Stack removed$(NC)"; \
	else \
		echo "$(RED)✗ Stack '$(SUBSYSTEM_STACK)' not found in current Docker context/host$(NC)"; \
		echo "$(YELLOW)Available stacks:$(NC)"; \
		docker stack ls --format '  - {{.Name}}' || true; \
		exit 1; \
	fi

status-subsystem:
	@echo "$(BLUE)Subsystem stack services:$(NC)"
	docker stack services $(SUBSYSTEM_STACK) 2>/dev/null || echo "$(RED)✗ Stack not found$(NC)"

logs-subsystem:
	@echo "$(BLUE)Following subsystem container logs (Ctrl+C to exit)...$(NC)"
	docker service logs -f --tail=100 $(SUBSYSTEM_SERVICE)

restart-subsystem: stop-subsystem start-subsystem
	@echo "$(GREEN)✓ Subsystem stack restarted$(NC)"

# ============================================================================
# LOCAL DEVELOPMENT (Docker Run)
# ============================================================================

start-dev:
	@echo "$(BLUE)Starting local development container...$(NC)"
	docker stop $(DEV_CONTAINER) 2>/dev/null && docker rm $(DEV_CONTAINER) 2>/dev/null || true
	docker run -d \
		--name $(DEV_CONTAINER) \
		-e PUID=1000 \
		-e PGID=1000 \
		-e TZ=America/Phoenix \
		-p $(DEV_PORT):8443 \
		-v $(CURRENT_DIR):/workspace \
		-v $(CURRENT_DIR)/config:/config \
		--restart unless-stopped \
		$(DEV_IMAGE)
	@echo "$(GREEN)✓ Code server is starting...$(NC)"
	@echo "$(YELLOW)Access it at: http://localhost:$(DEV_PORT)$(NC)"
	@echo "$(YELLOW)(Uses HTTP, not HTTPS)$(NC)"

stop-dev:
	@echo "$(BLUE)Stopping local development container...$(NC)"
	docker stop $(DEV_CONTAINER) 2>/dev/null && docker rm $(DEV_CONTAINER) 2>/dev/null && \
		echo "$(GREEN)✓ Container stopped and removed$(NC)" || \
		echo "$(YELLOW)Container not running$(NC)"

logs-dev:
	@echo "$(BLUE)Following local development container logs (Ctrl+C to exit)...$(NC)"
	docker logs -f $(DEV_CONTAINER)

restart-dev: stop-dev start-dev
	@echo "$(GREEN)✓ Local development container restarted$(NC)"

# ============================================================================
# UTILITY
# ============================================================================

clean:
	@echo "$(BLUE)Cleaning up resources...$(NC)"
	docker system prune -f 2>/dev/null || true
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

.PHONY: start-subsystem stop-subsystem status-subsystem logs-subsystem restart-subsystem
.PHONY: start-dev stop-dev logs-dev restart-dev
.PHONY: network-create clean help
