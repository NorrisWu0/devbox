FROM debian:trixie-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates git \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/jdx/mise:2026.11.5 /usr/local/bin/mise /usr/local/bin/mise
