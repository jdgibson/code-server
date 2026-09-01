.PHONY: start-dev stop-dev logs-dev help

# Container configuration
CONTAINER_NAME ?= code-server-dev
IMAGE ?= lscr.io/linuxserver/code-server:latest
PORT ?= 8443
CURRENT_DIR := $(shell pwd)

help:
	@echo "Code Server Makefile targets:"
	@echo "  make start-dev   - Start code-server container on http://localhost:$(PORT)"
	@echo "  make stop-dev    - Stop the running code-server container"
	@echo "  make logs-dev    - Show logs from the code-server container"
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
