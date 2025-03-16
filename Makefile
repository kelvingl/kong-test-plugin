PLUGIN_NAME ?= kong-test-plugin
DOCKER_COMPOSE_FILE ?= docker-compose.yml
KONG_VERSION ?= 2.8.4
DOCKER_COMPOSE_BIN ?= $(shell if command -v docker-compose >/dev/null 2>&1; then echo "docker-compose"; else echo "docker-compose.exe"; fi)
PONGO_BIN ?= pongo/pongo.sh
.DEFAULT_GOAL := help

export_envs = PLUGIN_NAME=$(PLUGIN_NAME) KONG_VERSION=$(KONG_VERSION)

help: ## Show this help.
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

.PHONY: start
start: up

.PHONY: up
up: ## Start plugin environment.
	$(export_envs) $(DOCKER_COMPOSE_BIN) --file $(DOCKER_COMPOSE_FILE) up -d

.PHONY: stop
stop: down

.PHONY: down
down: ## Stop plugin environment.
	$(export_envs) $(DOCKER_COMPOSE_BIN) --file $(DOCKER_COMPOSE_FILE) down -v

.PHONY: restart
restart: down up ## Restart plugin environment.

.PHONY: test 
test: ## Run pongo tests.
	$(export_envs) $(PONGO_BIN) run -- ./spec

.PHONY: logs
logs: ## Get logs.
	$(export_envs) $(DOCKER_COMPOSE_BIN) --file $(DOCKER_COMPOSE_FILE) logs --follow kong

.PHONY: install-pongo
install-pongo: ## Clone pongo
	@git clone https://github.com/Kong/kong-pongo.git pongo

