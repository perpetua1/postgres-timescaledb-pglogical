SHELL := /bin/bash

# https://stackoverflow.com/a/27132934/10787890
THIS_FILE := $(lastword $(MAKEFILE_LIST))

.DEFAULT_GOAL := help

# .PHONY to ensure no filenames collide with targets in this file
.PHONY: $(shell awk 'BEGIN {FS = ":"} /^[^ .:]+:/ {printf "%s ", $$1}' $(MAKEFILE_LIST))

PG_MAJOR := 14


EXTRA_DOCKER_BUILD_ARGS=--load

build: ## Build
	# No real idea what this buildx builder stuff is or if this is exactly correct
	docker buildx rm postgres-timescaledb-pglogical-$(PG_MAJOR) || true
	docker buildx create --name postgres-timescaledb-pglogical-$(PG_MAJOR) --use
	DOCKER_BUILDKIT=1 docker buildx build \
		-f Dockerfile \
		$(EXTRA_DOCKER_BUILD_ARGS) \
		--tag perpetua1/postgres-timescaledb-pglogical:$(PG_MAJOR)-latest \
		.

	docker buildx rm postgres-timescaledb-pglogical-$(PG_MAJOR)

build-and-push: EXTRA_DOCKER_BUILD_ARGS=--push --platform linux/amd64,linux/arm64
build-and-push: build  ## Build and push to dockerhub

# Self-Documented Makefile see https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## When you just dont know what to do with your life, look for inspiration here!
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
