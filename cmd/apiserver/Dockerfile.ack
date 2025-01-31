ARG BASE_IMAGE
# Build the manager binary
FROM --platform=${BUILDPLATFORM:-linux/amd64} golang:1.18-alpine as builder
ARG GOPROXY
ENV GOPROXY=${GOPROXY:-https://goproxy.cn}
WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY cmd/apiserver/main.go cmd/apiserver/main.go
COPY pkg/ pkg/

# Build
ARG TARGETARCH

RUN GO111MODULE=on CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} \
    go build -a -ldflags "-s -w" \
    -o vela-prism-${TARGETARCH} cmd/apiserver/main.go

FROM registry.cn-hangzhou.aliyuncs.com/acs/alpine:3.13-base
# This is required by daemon connnecting with cri
#RUN apk add --no-cache ca-certificates bash expat
#RUN apk add curl

WORKDIR /

ARG TARGETARCH
COPY --from=builder /workspace/vela-prism-${TARGETARCH} /usr/local/bin/vela-prism

CMD ["vela-prism"]
