GOOS ?= $(shell go env GOOS)
GOARCH ?= $(shell go env GOARCH)
GOPATH ?= $(shell go env GOPATH)
TARGETARCH ?= amd64

FIPS_ENABLE ?= ""
BUILDER_GOLANG_VERSION ?= 1.22
BUILD_ARGS = --build-arg CRYPTO_LIB=${FIPS_ENABLE} --build-arg BUILDER_GOLANG_VERSION=${BUILDER_GOLANG_VERSION}

NMI_IMG ?= "gcr.io/spectro-dev-public/jayeshsrivastava/aad-pod-identity"
IMG_TAG ?= "20240627"

docker-base:


docker-base-fips:
	docker buildx build --platform "linux/amd64,linux/arm64" --push . -t gcr.io/spectro-dev-public/jayeshsrivastava/aad-pod-identity/nmi-base:20241505 -f Dockerfile-base


#########################################################
#############        NMI Image Build       ##############
#########################################################
ALL_ARCH = amd64 arm64

.PHONY: docker-build
docker-build:
	docker buildx build --load --platform linux/${ARCH} ${BUILD_ARGS} -t ${NMI_IMG}-${ARCH}:${IMG_TAG} -f Dockerfile-spectro --target nmi-fips .

.PHONY: nmi-docker-build-all ## Build all the architecture docker images
nmi-docker-build-all: $(addprefix docker-build-,$(ALL_ARCH))

docker-build-%: ## Build docker images for a given ARCH
	$(MAKE) ARCH=$* docker-build

.PHONY: docker-push
docker-push: ## Push the docker image
	docker push ${NMI_IMG}-${ARCH}:${IMG_TAG}

.PHONY: nmi-docker-push-all ## Push all the architecture docker images
nmi-docker-push-all: $(addprefix docker-push-,$(ALL_ARCH))
	$(MAKE) docker-push-manifest

docker-push-%: ## Docker push
	$(MAKE) ARCH=$* docker-push

.PHONY: docker-push-manifest
docker-push-manifest: ## Push the manifest image
	docker manifest create --amend ${NMI_IMG}:${IMG_TAG} $(shell echo $(ALL_ARCH) | sed -e "s~[^ ]*~$(NMI_IMG)\-&:$(IMG_TAG)~g")
	@for arch in $(ALL_ARCH); do docker manifest annotate --arch $${arch} ${NMI_IMG}:${IMG_TAG} ${NMI_IMG}-$${arch}:${IMG_TAG}; done
	docker manifest push --purge ${NMI_IMG}:${IMG_TAG}