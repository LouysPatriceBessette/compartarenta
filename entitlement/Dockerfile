# syntax=docker/dockerfile:1.7
FROM golang:1.26-alpine AS builder
RUN apk add --no-cache git ca-certificates && \
    go install golang.org/x/vuln/cmd/govulncheck@latest
WORKDIR /src
COPY go.mod go.sum* ./
RUN go mod download
COPY . .
ARG BUILD_DIGEST=dev
RUN govulncheck ./... && \
    CGO_ENABLED=0 GOOS=linux go build \
      -trimpath \
      -ldflags="-s -w -X github.com/compartarenta/entitlement/internal/version.Build=${BUILD_DIGEST}" \
      -o /out/entitlement ./cmd/entitlement

FROM scratch AS runtime
USER 65532:65532
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /out/entitlement /entitlement
EXPOSE 8080
ENTRYPOINT ["/entitlement"]
