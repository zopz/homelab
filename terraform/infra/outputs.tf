resource "local_file" "vm_inventory" {
  content = yamlencode(
    {
      "all" : {
        "gateways" : [for cidr in proxmox_lxc.gateway.*.network.0 : trimsuffix(cidr.ip, "/16")],
        "masters" : proxmox_vm_qemu.kube_master.*.default_ipv4_address,
        "workers" : proxmox_vm_qemu.kube_worker.*.default_ipv4_address
      }
    }
  )
  filename = "${path.module}/../../inventories/vm.yaml"
}
