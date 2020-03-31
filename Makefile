SHELL := /bin/bash -x

# step to call before running any of the following, ensures that requisite environment variables for build are set
.PHONY: images_check_env
images_check_env:
ifndef BUILD_NUMBER
	$(error BUILD_NUMBER is undefined - cannot proceed with step)
endif
ifndef DOCKER_REPO
	$(error DOCKER_REPO is undefined - cannot proceed with step)
endif
ifndef GIT_BRANCH
	$(error GIT_BRANCH is undefined - cannot proceed with step)
endif

# here we set the variables that are used in the building, pushing, and removing of images
.PHONY: images_set_build_variables
images_set_build_variables: images_check_env
	$(eval docker_build_tag := "buildtag_$(BUILD_NUMBER)")
	$(eval tagged_image_list := $(shell docker images | grep "$(docker_build_tag)" | cut -d" " -f1 | cat))
	$(eval git_tag_for_current_branch := $(shell git tag --points-at)) #will be non-empty if HEAD is tagged
	$(eval git_latest_tag := $(shell git tag | sort -V -f | grep -E "^[v|V][0-9]+\.[0-9]+\.[0-9]+$$" | tail -n 1))

# This target will build out the images, passing the correct environment vars to fill out repo and tags
.PHONY: build
build: images_set_build_variables
	DOCKER_REPO=$$DOCKER_REPO BUILDTAG=$(docker_build_tag) docker-compose build --no-cache

.PHONY: test
test: images_set_build_variables
	DOCKER_REPO=$$DOCKER_REPO BUILDTAG=$(docker_build_tag) docker-compose run --rm e2e version
	DOCKER_REPO=$$DOCKER_REPO BUILDTAG=$(docker_build_tag) docker-compose run --rm e2e verify

# This target will iterate through all images and tags, pushing up versions of all with approriate tags
.PHONY: publish_images
publish_images: images_set_build_variables
	TAGSFORBRANCH=""; \
	if [ $(GIT_BRANCH) = "master" ]; then \
		TAGSFORBRANCH="master";\
	fi; \
	if [ $(GIT_BRANCH) = "develop" ]; then \
		TAGSFORBRANCH="develop";\
	fi; \
	if [ "$(git_latest_tag)" = "$(git_tag_for_current_branch)" ]; then TAGSFORBRANCH="$(TAGSFORBRANCH) latest"; fi; \
	echo "$(shell git tag --points-at)"; \
	echo $$TAGSFORBRANCH; \
	for repository in $(tagged_image_list); do \
		for tagname in $$TAGSFORBRANCH $(git_tag_for_current_branch); do \
			echo "pushing " $$repository:$$tagname; \
			docker tag $$repository:$(docker_build_tag) $$repository:$$tagname; \
			#docker push $$repository:$$tagname; \
		done; \
	done

# Removes all images in this BUILD_NUMBER
.PHONY: remove
remove: images_set_build_variables
	docker-compose down; \
	for repository in $(tagged_image_list); do \
		docker rmi $$repository:$(docker_build_tag) -f; \
	done
