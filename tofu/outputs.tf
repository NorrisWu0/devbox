locals {
  lan_ipv4 = flatten([
    for index, addresses in proxmox_virtual_environment_vm.devbox.ipv4_addresses : addresses
    if can(regex("^(en|eth)", proxmox_virtual_environment_vm.devbox.network_interface_names[index]))
  ])
}

output "vm_id" {
  description = "Proxmox-assigned VM ID."
  value       = proxmox_virtual_environment_vm.devbox.vm_id
}

output "ipv4_addresses" {
  description = "IPv4 addresses on Ethernet interfaces; excludes loopback and Tailscale."
  value       = local.lan_ipv4
}

output "ansible_inventory" {
  description = "JSON inventory; save locally after apply and use with ansible-playbook."
  value = jsonencode({
    all = {
      children = {
        devboxes = {
          hosts = {
            "devbox-vm" = {
              ansible_host = one(local.lan_ipv4)
              ansible_user = "norris"
            }
          }
        }
      }
    }
  })
}
