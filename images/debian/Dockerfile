FROM debian:trixie-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates git openssh-server \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /etc/ssh/ssh_host_*

COPY --from=ghcr.io/jdx/mise:2026.11.5 /usr/local/bin/mise /usr/local/bin/mise
