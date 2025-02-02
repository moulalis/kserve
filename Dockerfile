# Build the manager binary
FROM registry.access.redhat.com/ubi8/go-toolset:1.22 as builder

# These built-in args are defined in the global scope, and are not automatically accessible within build stages or RUN commands.
# To expose these arguments inside the build stage, we need to redefine it without a value.
ARG TARGETOS TARGETARCH
RUN echo "GOOS=${TARGETOS} GOARCH=${TARGETARCH}"

# Copy in the go src
WORKDIR /go/src/github.com/kserve/kserve
COPY go.mod  go.mod
COPY go.sum  go.sum

RUN go mod download

COPY cmd/    cmd/
COPY pkg/    pkg/

# Build
USER root
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} GOFLAGS=-mod=mod go build -a -o manager ./cmd/manager

# Use distroless as minimal base image to package the manager binary
FROM registry.access.redhat.com/ubi8/ubi-minimal:latest
RUN microdnf install -y shadow-utils && \
    microdnf clean all && \
    useradd kserve -m -u 1000
RUN microdnf remove -y shadow-utils
COPY third_party/ /third_party/
COPY --from=builder /go/src/github.com/kserve/kserve/manager /
USER 1000:1000

ENTRYPOINT ["/manager"]
