# syntax=docker/dockerfile:1.7
#
# Compartarenta relay container image.
#
# Two stages: a builder that compiles the Go binary, and a `scratch`-based
# runtime stage that contains only the binary, CA certificates, and the
# tzdata bundle. The resulting image is single-purpose: there is no shell,
# no package manager, no other process. This satisfies
# `relay-deployment-topology` / "The deployment runs without unrelated
# workloads in relay containers" and
# `relay-security-baseline` / "The relay process runs with least
# privilege".

# ---------------------------------------------------------------------------
# Builder
# ---------------------------------------------------------------------------
FROM golang:1.26-alpine AS builder

# Refuse to build with vulnerable dependencies. The audit step is part of
# the build pipeline per `relay-security-baseline` /
# "Dependency hygiene is enforced in the build pipeline".
RUN apk add --no-cache git ca-certificates && \
    go install golang.org/x/vuln/cmd/govulncheck@latest

WORKDIR /src
COPY go.mod go.sum* ./
RUN go mod download

COPY . .
ARG BUILD_DIGEST=dev

RUN govulncheck ./... \
 && CGO_ENABLED=0 GOOS=linux go build \
      -trimpath \
      -ldflags="-s -w -X github.com/compartarenta/relay/internal/version.Build=${BUILD_DIGEST}" \
      -o /out/relay ./cmd/relay

# ---------------------------------------------------------------------------
# Runtime
# ---------------------------------------------------------------------------
FROM scratch AS runtime

# Non-root UID (matches the value documented in compose.yml). The relay
# never writes outside the data volume, so the root filesystem can be
# mounted read-only by the deployment manifest.
USER 65532:65532

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /out/relay /relay

EXPOSE 8080 9090

# No HEALTHCHECK directive in the image itself: orchestrator-side
# liveness/readiness probes against /healthz and /readyz are documented
# in `docs/relay-deployment.md`. Keeping HEALTHCHECK out of the image
# lets the orchestrator choose the cadence without rebuilding.

ENTRYPOINT ["/relay"]
