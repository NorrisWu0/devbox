FROM archlinux:base

RUN pacman -Syu --noconfirm --needed ca-certificates git openssh \
    && pacman -Scc --noconfirm \
    && rm -f /etc/ssh/ssh_host_*

COPY --from=ghcr.io/jdx/mise:2026.11.5 /usr/local/bin/mise /usr/local/bin/mise
