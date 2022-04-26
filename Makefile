SHELL := /bin/bash

# https://stackoverflow.com/a/27132934/10787890
THIS_FILE := $(lastword $(MAKEFILE_LIST))

.DEFAULT_GOAL := help

# .PHONY to ensure no filenames collide with targets in this file
.PHONY: $(shell awk 'BEGIN {FS = ":"} /^[^ .:]+:/ {printf "%s ", $$1}' $(THIS_FILE))

build-and-push: ## Build and push to dockerhub
	docker buildx rm postgres-timescaledb-pglogical || true
	docker buildx create --name postgres-timescaledb-pglogical --use
	DOCKER_BUILDKIT=1 docker buildx build \
		-f Dockerfile \
		--push \
		--platform linux/amd64,linux/arm64 \
		--tag perpetua1/postgres-timescaledb-pglogical:14-latest \
		.

	docker buildx rm postgres-timescaledb-pglogical

# Self-Documented Makefile see https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## When you just dont know what to do with your life, look for inspiration here!
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
