.PHONY: start-dev stop-dev logs-dev deploy-nuc stop-nuc logs-nuc status-nuc help

# Container configuration
CONTAINER_NAME ?= code-server-dev
IMAGE ?= lscr.io/linuxserver/code-server:latest
PORT ?= 8443
CURRENT_DIR := $(shell pwd)
COMPOSE_NUC := docker compose --project-directory $(CURRENT_DIR) -f $(CURRENT_DIR)/docker-compose.yml

help:
	@echo "Code Server Makefile targets:"
	@echo "  make start-dev   - Start code-server container on http://localhost:$(PORT)"
	@echo "  make stop-dev    - Stop the running code-server container"
	@echo "  make logs-dev    - Show logs from the code-server container"
	@echo "  make deploy-nuc  - Deploy persistent code-server via Traefik on docker-nuc"
	@echo "  make stop-nuc    - Stop and remove the docker-nuc Compose service"
	@echo "  make logs-nuc    - Show logs from the docker-nuc Compose service"
	@echo "  make status-nuc  - Show docker-nuc Compose service status"
	@echo "  make help        - Show this help message"

start-dev:
	@echo "Starting code-server container..."
	docker run -d \
		--name $(CONTAINER_NAME) \
		-e PUID=1000 \
		-e PGID=1000 \
		-e TZ=Etc/UTC \
		-p $(PORT):8443 \
		-v $(CURRENT_DIR):/workspace \
		--restart unless-stopped \
		$(IMAGE)
	@echo "✓ Code server is starting..."
	@echo "  Access it at: http://localhost:$(PORT)"
	@echo "  (Uses HTTP, not HTTPS)"

stop-dev:
	@echo "Stopping code-server container..."
	docker stop $(CONTAINER_NAME) && docker rm $(CONTAINER_NAME)
	@echo "Container stopped and removed."

logs-dev:
	docker logs -f $(CONTAINER_NAME)

deploy-nuc:
	@echo "Run this target from this repository's checkout on docker-nuc.mmto.arizona.edu."
	$(COMPOSE_NUC) up -d
	@echo "Code-server is available at: https://subsystem.mmto.arizona.edu/code-server/"

stop-nuc:
	$(COMPOSE_NUC) down

logs-nuc:
	$(COMPOSE_NUC) logs -f code-server

status-nuc:
	$(COMPOSE_NUC) ps
