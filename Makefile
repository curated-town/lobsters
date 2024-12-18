#!/usr/bin/make -f


# import .env
ifneq (,$(wildcard ./.env))
	include .env
	export
endif


SHELL                   := /usr/bin/env bash
REPO_NAMESPACE          ?= curated
REPO_USERNAME           ?= jamesbrink
REPO_API_URL            ?= https://hub.docker.com/v2
IMAGE_NAME              ?= lobsters
BASE_IMAGE              ?= ruby:3.3.6-alpine
DEVELOPER_BUILD         ?= false
VERSION                 := $(shell git describe --tags --abbrev=0 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null)
VCS_REF                 := $(shell git rev-parse --short HEAD 2>/dev/null || echo "0000000")
BUILD_DATE              := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# Default target is to build container
.PHONY: default
default: build

.PHONY: installcert
installcert:
	sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ./.local/caddy-data/caddy/pki/authorities/local/root.crt

# Build the docker image
.PHONY: build
build:
	docker build \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg DEVELOPER_BUILD=$(DEVELOPER_BUILD) \
		--build-arg VCS_REF=$(VCS_REF) \
		--build-arg VERSION=$(VERSION) \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):latest \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VCS_REF) \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VERSION) \
		--file Dockerfile .

.PHONY: prodbuild
prodbuild:
	docker build \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg DEVELOPER_BUILD=$(DEVELOPER_BUILD) \
		--build-arg VCS_REF=$(VCS_REF) \
		--build-arg VERSION=$(VERSION) \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):latest \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VCS_REF) \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VERSION) \
		--file Dockerfile.prod .

.PHONY: produp
produp:
	docker compose -f docker-compose-prod.yaml up

.PHONY: forceprodup
forceprodup:
	make prodclean && docker compose -f docker-compose-prod.yaml up --build
.PHONY: prodclean
prodclean:
	docker compose -f docker-compose-prod.yaml down && 	docker compose -f docker-compose-prod.yaml down -v
# List built images
.PHONY: list
list:
	docker images $(REPO_NAMESPACE)/$(IMAGE_NAME) --filter "dangling=false"

# Run any tests
.PHONY: test
test:
	docker run -t $(REPO_NAMESPACE)/$(IMAGE_NAME) env | grep VERSION | grep $(VERSION)

# Push images to repo
.PHONY: push
push:
	echo "$$REPO_PASSWORD" | docker login -u "$(REPO_USERNAME)" --password-stdin; \
		docker push  $(REPO_NAMESPACE)/$(IMAGE_NAME):latest; \
		docker push  $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VCS_REF); \
		docker push  $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VERSION);

# Update README on registry
.PHONY: push-readme
push-readme:
	echo "Authenticating to $(REPO_API_URL)"; \
		token=$$(curl -s -X POST -H "Content-Type: application/json" -d '{"username": "$(REPO_USERNAME)", "password": "'"$$REPO_PASSWORD"'"}' $(REPO_API_URL)/users/login/ | jq -r .token); \
		code=$$(jq -n --arg description "$$(<README.md)" '{"registry":"registry-1.docker.io","full_description": $$description }' | curl -s -o /dev/null  -L -w "%{http_code}" $(REPO_API_URL)/repositories/$(REPO_NAMESPACE)/$(IMAGE_NAME)/ -d @- -X PATCH -H "Content-Type: application/json" -H "Authorization: JWT $$token"); \
		if [ "$$code" != "200" ]; \
		then \
			echo "Failed to update README.md"; \
			exit 1; \
		else \
			echo "Success"; \
		fi;

# Trigger update of micro-badge
.PHONY: update-micro-badge
update-micro-badge:
	curl -d 'update' "https://hooks.microbadger.com/images/$(REPO_NAMESPACE)/$(IMAGE_NAME)/$$MICROBADGER_TOKEN"

# Remove existing images
.PHONY: clean
clean:
	docker rmi $$(docker images $(REPO_NAMESPACE)/$(IMAGE_NAME) --format="{{.Repository}}:{{.Tag}}") --force
