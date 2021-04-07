FROM --platform=${BUILDPLATFORM:-linux/amd64} golang:1.13-alpine as builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

ARG GIT_COMMIT
ARG VERSION

ENV GO111MODULE=on
ENV CGO_ENABLED=0
ENV GOPATH=/go/src/
WORKDIR /go/src/github.com/inlets/inlets

COPY .git               .git
COPY vendor             vendor
COPY go.mod             .
COPY go.sum             .
COPY pkg                pkg
COPY cmd                cmd
COPY main.go            .

RUN test -z "$(gofmt -l $(find . -type f -name '*.go' -not -path "./vendor/*" -not -path "./function/vendor/*"))" || { echo "Run \"gofmt -s -w\" on your Golang code"; exit 1; }
# RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go test -mod=vendor $(go list ./... | grep -v /vendor/)

RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} CGO_ENABLED=0 go build -mod=vendor -ldflags "-s -w -X main.GitCommit=${GIT_COMMIT} -X main.Version=${VERSION}" -a -installsuffix cgo -o /usr/bin/inlets

FROM alpine

ARG REPO_URL

LABEL org.opencontainers.image.source $REPO_URL

COPY --from=builder /etc/passwd /etc/group /etc/
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/bin/inlets /usr/bin/
RUN apk update && apk add ca-certificates && rm -rf /var/cache/apk/*

COPY docker-entrypoint.sh /usr/bin/docker-entrypoint.sh
RUN chmod +x /usr/bin/docker-entrypoint.sh

EXPOSE 80

VOLUME /tmp/

ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
CMD ["--help"]
