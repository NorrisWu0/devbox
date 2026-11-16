#!/bin/sh
set -eu

: "${PROXMOX_VE_CA_CERT:?Set PROXMOX_VE_CA_CERT through Infisical}"
umask 077
ca_file=$(mktemp)
trap 'rm -f "$ca_file"' EXIT
trap 'exit 130' INT
trap 'exit 143' HUP TERM
printf '%s\n' "$PROXMOX_VE_CA_CERT" > "$ca_file"
export SSL_CERT_FILE="$ca_file"
unset PROXMOX_VE_CA_CERT

tofu -chdir=tofu "$@"
