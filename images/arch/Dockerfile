FROM archlinux:base

RUN pacman -Syu --noconfirm --needed ca-certificates git \
    && pacman -Scc --noconfirm

COPY --from=ghcr.io/jdx/mise:2026.11.5 /usr/local/bin/mise /usr/local/bin/mise
