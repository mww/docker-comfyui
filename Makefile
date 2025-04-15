#!/usr/bin/make -f

SHELL                   := /usr/bin/env bash
REPO_USERNAME           ?= mww
REPO_API_URL            ?= registry.weavers.me
IMAGE_NAME              ?= comfyui
CUDA_VERSION            ?= 12.2.2
BASE_IMAGE              ?= nvidia/cuda:$(CUDA_VERSION)-devel-ubuntu22.04
MODELS                  ?= false
SED                     := $(shell [[ `command -v gsed` ]] && echo gsed || echo sed)
BUILD_DATE              := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
VERSION                 := v0.3.26
UI_MANAGER_VERSION      ?= main

# Default target is to build container
.PHONY: default
default: base

# Build the docker image
.PHONY: base
base:
	docker build \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VERSION=$(VERSION) \
		--tag $(REPO_API_URL)/$(IMAGE_NAME):$(VERSION) \
		--target=base \
		--file Dockerfile .; \

push-base: base
	docker push $(REPO_API_URL)/$(IMAGE_NAME):$(VERSION);

.PHONY: sd-1.5
sd-1.5: base
	docker build \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VERSION=$(VERSION) \
		--tag $(IMAGE_NAME):sd-1.5 \
		--tag $(IMAGE_NAME):$(VERSION)-sd-1.5 \
		--target=sd-1.5 \
		--file Dockerfile .; \

push-sd-1.5: sd-1.5
	docker push  $(IMAGE_NAME):sd-1.5; \
	docker push  $(IMAGE_NAME):$(VERSION)-sd-1.5;

.PHONY: sd-turbo
sd-turbo: base
	docker build \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VERSION=$(VERSION) \
		--tag $(IMAGE_NAME):sd-turbo \
		--tag $(IMAGE_NAME):$(VERSION)-sd-turbo \
		--target=sd-turbo \
		--file Dockerfile .; \

push-sd-turbo: sd-turbo
	docker push  $(IMAGE_NAME):sd-turbo; \
	docker push  $(IMAGE_NAME):$(VERSION)-sd-turbo;

.PHONY: svd-14-frame
svd-14-frame: base
	docker build \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VERSION=$(VERSION) \
		--tag $(IMAGE_NAME):svd-14-frame \
		--tag $(IMAGE_NAME):$(VERSION)-svd-14-frame \
		--target=svd-14-frame \
		--file Dockerfile .; \

push-svd-14-frame: svd-14-frame
	docker push  $(IMAGE_NAME):svd-14-frame; \
	docker push  $(IMAGE_NAME):$(VERSION)-svd-14-frame;

.PHONY: svd-25-frame
svd-25-frame: base
	docker build \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VERSION=$(VERSION) \
		--tag $(IMAGE_NAME):svd-25-frame \
		--tag $(IMAGE_NAME):$(VERSION)-svd-25-frame \
		--target=svd-25-frame \
		--file Dockerfile .; \

push-svd-25-frame: svd-25-frame
	docker push  $(IMAGE_NAME):svd-25-frame; \
	docker push  $(IMAGE_NAME):$(VERSION)-svd-25-frame;

.PHONY: svd
svd: base
	docker build \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VERSION=$(VERSION) \
		--tag $(IMAGE_NAME):svd \
		--tag $(IMAGE_NAME):$(VERSION)-svd \
		--target=svd \
		--file Dockerfile .; \

push-svd: svd
	docker push  $(IMAGE_NAME):svd; \
	docker push  $(IMAGE_NAME):$(VERSION)-svd;

.PHONY: all-models
all-models: base sd-turbo sd-1.5 svd-14-frame svd-25-frame svd
	docker build \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VERSION=$(VERSION) \
		--tag $(IMAGE_NAME):all-models \
		--tag $(IMAGE_NAME):$(VERSION)-all-models \
		--file Dockerfile .; \

push-all-models: all-models
	docker push  $(IMAGE_NAME):all-models; \
	docker push  $(IMAGE_NAME):$(VERSION)-all-models;

# List built images
.PHONY: list
list:
	docker images $(IMAGE_NAME) --filter "dangling=false"

# Run any tests
.PHONY: test
test:
	docker run -t $(IMAGE_NAME) env | grep VERSION | grep $(VERSION)

# Remove existing images
.PHONY: clean
clean:
	docker rmi $$(docker images $(IMAGE_NAME) --format="{{.Repository}}:{{.Tag}}") --force
