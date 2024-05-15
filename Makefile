GOOS ?= $(shell go env GOOS)
GOARCH ?= $(shell go env GOARCH)
GOPATH ?= $(shell go env GOPATH)
TARGETARCH ?= amd64

FIPS_ENABLE ?= ""
BUILDER_GOLANG_VERSION ?= 1.22

IMG_PATH ?= "gcr.io/spectro-dev-public/jayeshsrivastava/aad-pod-identity"
IMG_TAG ?= "20241505"
IMG_SERVICE_URL ?= ${IMG_PATH}
NMI_IMG ?= ${IMG_SERVICE_URL}:${IMG_TAG}

docker:
	docker buildx build \
		--platform linux/amd64 \
		--push . -t ${NMI_IMG} \
		--build-arg BUILDER_GOLANG_VERSION=${BUILDER_GOLANG_VERSION} \
		-f Dockerfile-spectro \
		--target nmi

docker-fips:
	docker buildx build \
		--platform linux/amd64 \
		--push . -t ${NMI_IMG}-fips \
		--build-arg CRYPTO_LIB=yes \
		--build-arg BUILDER_GOLANG_VERSION=${BUILDER_GOLANG_VERSION} \
		-f Dockerfile-spectro \
		--target nmi-fips

docker-base:


docker-base-fips:
	docker buildx build --platform "linux/amd64,linux/arm64" --push . -t gcr.io/spectro-dev-public/jayeshsrivastava/aad-pod-identity/nmi-base:20241505 -f Dockerfile-base
