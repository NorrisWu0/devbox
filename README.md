# Devbox

## Proxmox VM

`tofu/` provisions one Debian VM; `ansible/devbox.yml` configures it. No Docker is installed in the VM, and the existing Kubernetes devbox is untouched.

The first VM uses static settings in `tofu/main.tf`: `proxmox-02`, `vmbr0` with DHCP, 4 shared vCPUs, 2–8 GiB ballooned RAM, a 16 GiB system disk, and a 32 GiB home disk on `local-lvm`. `tofu/cloud-init.yaml` contains user `norris` and the public SSH key. The Debian image is pinned by release and SHA-512; provider versions are locked.

### Provision

Run `mise install` on the host to install pinned OpenTofu, Ansible, and Infisical from `mise.toml`; Python and uv support Ansible's isolated installation. OpenSSH must also be installed on the host. Use `mise exec --` before the commands below if mise is not activated in your shell.

The API endpoint is fixed at `https://10.0.0.231:8006/` in `tofu/versions.tf`. TLS verification stays enabled. Store the PEM-encoded Proxmox CA obtained through a trusted console or SSH connection as `PROXMOX_VE_CA_CERT` in Infisical.

`make vm-plan` and `make vm-apply` use the project configured in `.infisical.yaml`, with environment `prod` and folder `/devbox`. Store `PROXMOX_VE_API_TOKEN` there in complete provider format, `user@realm!token-name=secret`, alongside `PROXMOX_VE_CA_CERT`. The wrapper writes the CA to a temporary owner-only file, sets `SSL_CERT_FILE` for OpenTofu, and removes the file on exit. The API token stays in the child process environment; neither value is printed or exported into your terminal.

Select the SSH agent separately:

```sh
export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
```

The configured Proxmox SSH user (`root`) must authorize an agent key. This is separate from the API token and the VM user's authorized public key.

Before applying, confirm node capacity, DHCP and LAN reachability. `nfs-image` must allow Import content; `nfs-cloudinit` must allow Snippets, and both must be available to `proxmox-02`. VM disks remain on `local-lvm`. The provider needs API rights to create/configure/start VMs and download images, plus SSH access to upload snippets. Review [provider requirements](https://bpg.sh/docs/) rather than granting an unrestricted API token.

```sh
tofu -chdir=tofu init
make vm-plan
# Review the saved plan before creating anything.
make vm-apply
install -d -m 0700 .local
tofu -chdir=tofu output -raw ansible_inventory > .local/ansible-inventory.json
```

The guest agent supplies the DHCP address in the generated inventory. Before running Ansible, verify the VM's SSH host-key fingerprint through the Proxmox console and run `cloud-init status --wait` in the guest. Cloud-init creates UID 1000, prepares `/home`, installs Python/sudo and starts the guest agent. Ansible bootstrap access requires LAN routing; Tailscale is not enrolled yet.

### Configure

One playbook imports `system`, `ssh`, `mise`, and `tailscale` task files. Linux and Tailscale hostnames follow the generated inventory name; Ansible also configures cloud-init to retain existing SSH host keys when bootstrap metadata changes. For first enrollment, generate a single-use, non-ephemeral Tailscale auth key with the intended tag and access policy:

```sh
read -rsp 'Tailscale auth key: ' TAILSCALE_AUTH_KEY; printf '\n'
export TAILSCALE_AUTH_KEY
ansible-playbook -i .local/ansible-inventory.json ansible/devbox.yml
unset TAILSCALE_AUTH_KEY
```

Already authenticated VMs do not need another enrollment key. Secret tasks are redacted and temporary credentials removed on failure. Re-run this playbook for ongoing configuration; cloud-init is bootstrap, so editing its user/key settings does not reconfigure an existing instance automatically. Re-export the inventory after address changes.

### Data safety

The serial-addressed home disk mounts at `/home` before user creation. It is formatted only when signature-free; unexpected filesystems or labels are rejected. SSH remains unavailable if the home mount validation fails. Keep work, tool installs and personal settings under your home.

OpenTofu `prevent_destroy` and Proxmox VM protection block routine VM replacement/deletion and disk removal. **The home disk is still owned by this VM, not an independently retained OpenTofu resource.** Do not remove either protection to force a plan through. Before any OS replacement, take and verify a backup, then explicitly plan how the existing home disk will be retained and reattached with UID 1000. The server's SSH host keys live on the system disk; a deliberate OS rebuild changes its identity.

Disk backup inclusion is enabled, but this does not create a backup schedule. State is local and ignored by Git; protect and back up `tofu/terraform.tfstate`. Do not share the unrelated infrastructure root's state.

Once configured, follow the [getting-started guide](docs/getting-started.md) to connect through Tailscale.

## Base images

Each base image has its own directory under `images/`.

- [`images/debian/Dockerfile`](images/debian/Dockerfile): Debian 13 (`trixie-slim`) with Git, mise, CA certificates, and the OpenSSH server.
- [`images/arch/Dockerfile`](images/arch/Dockerfile): Arch Linux with the same tools.

Build locally with Docker:

```sh
make build
```

Build the Arch image:

```sh
make build-arch
```

Run Debian locally with SSH in the first terminal:

```sh
make run
```

Wait for `Server listening`, then connect from a second terminal:

```sh
make ssh
```

The local runner creates user `devbox` and generates fresh SSH host keys at startup; no packages are downloaded. Host keys are not included in either image. It accepts public-key login on `127.0.0.1:2222` only. The host keeps the generated test key in `.local/ssh/`; only its public key is mounted into the devbox.

Optional overrides: `CONTAINER_NAME`, `SSH_PORT`, and `SSH_DIR`. Use the same `SSH_PORT` and `SSH_DIR` with `make ssh` when overriding them.

Press Ctrl+C in the first terminal to stop and remove the container. Files inside it are discarded; the local runner does not use the persistent Kubernetes workspace.

## Publishing

The `Publish images` GitHub Action runs on pushes to `master` or manually. It publishes Linux amd64 images using the repository's `GITHUB_TOKEN`:

- `ghcr.io/norriswu0/devbox-debian`
- `ghcr.io/norriswu0/devbox-arch`

Docker Metadata Action generates OCI labels and three image tags per commit: `latest`, the short SHA (7 characters), and the full SHA, with no prefix. After the first publish, set each package's visibility to **Public** in its GitHub package settings; GHCR creates new packages as private by default.

## Kubernetes workspace

The existing Kubernetes devbox is not changed by this setup. Its manifests and connection/operation instructions remain in [apps/devbox](https://github.com/NorrisWu0/apps/tree/main/devbox).
