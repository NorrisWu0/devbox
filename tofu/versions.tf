terraform {
  required_version = ">= 1.10.0, < 2.0.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.122.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://10.0.0.231:8006/"
  insecure = false
  ssh {
    agent    = true
    username = "root"
  }
}
