# syntax=docker/dockerfile:1
#
# Stage 1 - build the static site with a pinned Hugo release.
# Stage 2 - serve it with nginx as a non-root user on port 8080.
#
# Build locally:   docker build -t site:dev --build-arg BASE_URL=http://localhost:8080/ .
# Run locally:     docker run --rm -p 8080:8080 site:dev

ARG HUGO_VERSION=0.166.0

FROM debian:trixie-slim AS build
ARG HUGO_VERSION
ARG TARGETARCH
ARG BASE_URL=http://localhost:8080/

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl libstdc++6 \
 && rm -rf /var/lib/apt/lists/*

# Download Hugo extended and verify it against the official checksum file.
RUN set -eux; \
    arch="${TARGETARCH:-amd64}"; \
    file="hugo_extended_${HUGO_VERSION}_linux-${arch}.tar.gz"; \
    base="https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}"; \
    cd /tmp; \
    curl -fsSLO "${base}/${file}"; \
    curl -fsSLO "${base}/hugo_${HUGO_VERSION}_checksums.txt"; \
    grep " ${file}\$" "hugo_${HUGO_VERSION}_checksums.txt" | sha256sum -c -; \
    tar -xzf "${file}" -C /usr/local/bin hugo; \
    rm -f /tmp/hugo*; \
    hugo version

WORKDIR /src
COPY . .

# Fails loudly if the theme folder is missing.
RUN test -f themes/blowfish/theme.toml \
    || (echo "themes/blowfish is missing - it must be committed to the repo" && exit 1)

RUN hugo --gc --minify --panicOnWarning --baseURL "${BASE_URL}"


FROM nginxinc/nginx-unprivileged:stable-alpine AS runtime

LABEL org.opencontainers.image.description="Personal site - Hugo + Blowfish served by nginx"

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build --chown=nginx:nginx /src/public /usr/share/nginx/html

EXPOSE 8080
USER nginx

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/healthz || exit 1
