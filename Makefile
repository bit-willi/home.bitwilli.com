SHELL := /bin/bash
.DEFAULT_GOAL := help
DOCKER_COMPOSE := $(shell command -v docker-compose > /dev/null && echo "docker-compose" || echo "docker compose")
ARGS = `arg="$(filter-out $@,$(MAKECMDGOALS))" && echo $${arg:-${1}}`

.PHONY: help

help: ## Show this help message
	@echo "Docker - home.bitwilli.com"
	@echo "---------------------"
	@echo "Usage: make <command>"
	@echo ""
	@echo "Commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-26s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Maybe - finance control
maybe-start: ## Start maybe containers
	$(DOCKER_COMPOSE) -f docker-compose/maybe-docker-compose.yml up -d

maybe-stop: ## Stop maybe containers
	$(DOCKER_COMPOSE) -f docker-compose/maybe-docker-compose.yml down

maybe-logs: ## Attach to maybe containers logs
	$(DOCKER_COMPOSE) -f docker-compose/maybe-docker-compose.yml logs -f

maybe-recurrency: ## Run the recurrency script in the maybe database container.
	cat mods/maybe/recurrency/create_recurrencies.sql | docker exec -i docker-compose-db-1 psql -U maybe_user -d maybe_production

# Manga - download/read mangas
manga-start: ## Start containers (kaizoku, komga, tachidesk)
	$(DOCKER_COMPOSE) -f docker-compose/manga-docker-compose.yml up -d

manga-stop: ## Stop containers (kaizoku, komga, tachidesk)
	$(DOCKER_COMPOSE) -f docker-compose/manga-docker-compose.yml down

manga-logs: ## Attach to manga containers logs
	$(DOCKER_COMPOSE) -f docker-compose/manga-docker-compose.yml logs -f

# Media - download/watch movies n series
media-start: ## Start containers (qbittorrent, jackett, bazarr, overseerr, flaresolverr, radarr, readarr, sonarr, plex)
	$(DOCKER_COMPOSE) -f docker-compose/media-docker-compose.yml up -d

media-stop: ## Start containers (qbittorrent, jackett, bazarr, overseerr, flaresolverr, radarr, readarr, sonarr, plex)
	$(DOCKER_COMPOSE) -f docker-compose/media-docker-compose.yml down

media-logs: ## Attach to media containers logs
	$(DOCKER_COMPOSE) -f docker-compose/media-docker-compose.yml logs -f

# Net - DNS
net-start: ## Start containers (cloudflared, pihole)
	$(DOCKER_COMPOSE) -f docker-compose/net-docker-compose.yml up -d

net-stop: ## Stop containers (cloudflared, pihole)
	$(DOCKER_COMPOSE) -f docker-compose/net-docker-compose.yml down

net-logs: ## Attach to media containers logs
	$(DOCKER_COMPOSE) -f docker-compose/net-docker-compose.yml logs -f

# Utils - general tools
utils-start: ## Start containers (portainer, watchtower, vaultwarden)
	$(DOCKER_COMPOSE) -f docker-compose/utils-docker-compose.yml up -d

utils-stop: ## Stop containers (portainer, watchtower, vaultwarden)
	$(DOCKER_COMPOSE) -f docker-compose/utils-docker-compose.yml down

utils-logs: ## Attach to utils containers logs
	$(DOCKER_COMPOSE) -f docker-compose/utils-docker-compose.yml logs -f

net-restart: ## Restart net containers
	make stop-net
	make sleep
	make start-net

# Utils - global usable targes
sleep: # Sleep for 1 sec
	sleep 1
