locals {
  cloud_init = file("${path.module}/cloud-init.yaml")
}

resource "proxmox_download_file" "debian" {
  node_name           = "proxmox-02"
  datastore_id        = "nfs-image"
  content_type        = "import"
  file_name           = "debian-13-genericcloud-amd64-20261103-2651.qcow2"
  url                 = "https://cloud.debian.org/images/cloud/trixie/20261103-2651/debian-13-genericcloud-amd64-20261103-2651.qcow2"
  checksum_algorithm  = "sha512"
  checksum            = "d25999de0770d4cde1be72c299ba3ad94eac7ea8fd4d18f8cc86c69df69337e2e8a91d64465a9bfd8f2a78c566fcbcb0842eacc91c09efdef72d719d9f13b535"
  overwrite           = false
  overwrite_unmanaged = false
}

resource "proxmox_virtual_environment_file" "cloud_init" {
  node_name    = "proxmox-02"
  datastore_id = "nfs-cloudinit"
  content_type = "snippets"
  overwrite    = false
  source_raw {
    data      = local.cloud_init
    file_name = "devbox-${substr(sha256(local.cloud_init), 0, 12)}.cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "devbox" {
  name        = "devbox"
  node_name   = "proxmox-02"
  description = "Declarative Debian devbox; workspace data lives on the protected home disk."
  tags        = ["devbox", "opentofu"]
  protection  = true
  on_boot     = true
  boot_order  = ["virtio0"]

  cpu {
    cores = 4
    type  = "x86-64-v2-AES"
  }
  memory {
    dedicated = 8192
  }
  agent {
    enabled = true
    wait_for_ip {
      ipv4 = true
    }
  }
  disk {
    interface    = "virtio0"
    datastore_id = "local-lvm"
    import_from  = proxmox_download_file.debian.id
    size         = 16
    discard      = "on"
  }
  disk {
    interface    = "virtio1"
    serial       = "devbox-workspace"
    datastore_id = "local-lvm"
    size         = 32
    backup       = true
    discard      = "on"
  }
  disk {
    interface    = "virtio2"
    serial       = "devbox-swap"
    datastore_id = "local-lvm"
    size         = 4
    backup       = false
    discard      = "on"
  }
  initialization {
    datastore_id      = "local-lvm"
    user_data_file_id = proxmox_virtual_environment_file.cloud_init.id
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }
  network_device {
    bridge = "vmbr0"
  }
  operating_system {
    type = "l26"
  }
  serial_device {}

  lifecycle {
    prevent_destroy = true
  }
}
