IMAGE_NAME := gudari/kafka
BASE_IMAGE := gudari/java:8u201-b09
ZOOKEEPER_VERSION := 3.4.14

0X_VERSIONS := \
		0.11.0.3
1X_VERSIONS := \
		1.0.2 \
		1.1.1
2X_VERSIONS := \
		2.0.1 \
		2.1.1 \
		2.2.0

ALL_VERSIONS := $(0X_VERSIONS) $(1X_VERSIONS) $(2X_VERSIONS)

dockerfile:
	mkdir -p $(DOCKERFILE)/scripts
	cp bootstrap.sh $(DOCKERFILE)/scripts/bootstrap.sh
	docker run --rm -i -v $(PWD)/Dockerfile.template.erb:/Dockerfile.erb:ro \
		ruby:alpine erb -U -T 0 \
			dockerfile='$(DOCKERFILE)' \
			kafka_version='$(VERSION)' \
			scala_version='$(SCALA_VERSION)' \
			base_image='$(BASE_IMAGE)' \
		/Dockerfile.erb > $(DOCKERFILE)/Dockerfile

dockerfile-all:
	(set -e ; $(foreach ver, $(ALL_VERSIONS), \
		make dockerfile \
			DOCKERFILE=$(ver) \
			VERSION=$(ver) \
			SCALA_VERSION=2.11 ; \
	))

image:
	docker build -t $(IMAGE_NAME):$(VERSION) $(DOCKERFILE) --build-arg KAFKA_VERSION=$(VERSION) --build-arg SCALA_VERSION=$(SCALA_VERSION)

image-all:
	(set -e ; $(foreach ver,$(ALL_VERSIONS), \
		make image \
			DOCKERFILE=$(ver) \
			VERSION=$(ver) \
			SCALA_VERSION=2.11 ; \
	))

example:
	mkdir -p examples/$(DOCKERFILE)/basic
	cp kafka.env examples/$(DOCKERFILE)/basic/kafka.env
	cp zookeeper.env examples/$(DOCKERFILE)/basic/zookeeper.env
	docker run --rm -i -v $(PWD)/docker-compose.yml.erb:/docker-compose.yml.erb:ro \
		ruby:alpine erb -U -T - \
			version='$(VERSION)' \
			zookeeper_version='$(ZOOKEEPER_VERSION)' \
		/docker-compose.yml.erb > examples/$(DOCKERFILE)/basic/docker-compose.yml

	mkdir -p examples/$(DOCKERFILE)/zkui
	cp kafka.env examples/$(DOCKERFILE)/zkui/kafka.env
	cp zookeeper.env examples/$(DOCKERFILE)/zkui/zookeeper.env
	cp zkui.env examples/$(DOCKERFILE)/zkui/zkui.env
	docker run --rm -i -v $(PWD)/docker-compose-zkui.yml.erb:/docker-compose.yml.erb:ro \
		ruby:alpine erb -U -T - \
			version='$(VERSION)' \
			zookeeper_version='$(ZOOKEEPER_VERSION)' \
		/docker-compose.yml.erb > examples/$(DOCKERFILE)/zkui/docker-compose.yml

example-all:
	(set -e ; $(foreach ver,$(ALL_VERSIONS), \
		make example \
			DOCKERFILE=$(ver) \
			VERSION=$(ver) ; \
	))

src: dockerfile example

src-all:
	(set -e ; $(foreach ver,$(ALL_VERSIONS), \
		make src \
			DOCKERFILE=$(ver) \
			VERSION=$(ver) ; \
	))

build: src image

build-all:
	(set -e ; $(foreach ver,$(ALL_VERSIONS), \
		make build \
			DOCKERFILE=$(ver) \
			VERSION=$(ver) \
			SCALA_VERSION=2.11 ; \
	))

push:
	docker push $(IMAGE_NAME):$(VERSION)

push-all:
	(set -e ; $(foreach ver,$(ALL_VERSIONS), \
		make push \
			DOCKERFILE=$(ver) \
			VERSION=$(ver) \
			SCALA_VERSION=2.11 ; \
	))

release: build push

release-all:
	(set -e ; $(foreach ver,$(ALL_VERSIONS), \
		make release \
			DOCKERFILE=$(ver) \
			VERSION=$(ver) \
			SCALA_VERSION=2.11 ; \
	))

.PHONY: image image-all \
        push push-all \
		build build-all \
        release release-all \
        src src-all \
        dockerfile dockerfile-all \
		example example-all
