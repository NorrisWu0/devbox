# Getting started

Connect from your **host** (laptop) to the **remote** (Proxmox devbox VM).

## Before you start

- Connect the host to the Tailscale network that permits access to the devbox.
- Keep Bitwarden running and unlocked, with its SSH agent enabled and your SSH key available.
- First complete [VM provisioning and Ansible configuration](../README.md#proxmox-vm). This guide assumes the remote is running, enrolled in Tailscale, and allows your matching **public** key. Your private key stays in Bitwarden on the host.

## 1. Select the Bitwarden agent

In a real terminal on the host:

```sh
export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
ssh-add -l
```

Check that your key's fingerprint is listed. To use this agent in new terminals, add the `export` line to `~/.bashrc` (`~/.zshrc` for Zsh).

## 2. Connect

Before accepting the first SSH host-key prompt, open the VM's trusted Proxmox console and run `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`. Compare its fingerprint with the SSH prompt; stop if it differs.

```sh
ssh norris@devbox
```

Approve Bitwarden's signing request if prompted. If `devbox` does not resolve, use the VM's full Tailscale MagicDNS name instead. Investigate any unexpected changed-host-key warning rather than removing the saved key blindly.

## 3. Work and disconnect

Keep projects, mise tools, and configuration under `/home/norris`. `/home` is mounted from the separate persistent home disk. Protect and back up that disk before any VM replacement.

Run `exit` to disconnect. This does not stop the devbox or delete your workspace. Persistent storage is not a backup.
