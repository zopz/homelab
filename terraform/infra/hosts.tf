resource "null_resource" "lxc_templates" {
  count = length(var.hosts)
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_rsa")
      host        = var.hosts[count.index].ip
    }
    # Bootstrap script called with private_ip of each node in the cluster
    inline = [
      "pveam update && pveam download ${var.common.template_store} ${var.common.lvm_template}.tar.gz"
    ]
  }
}

resource "null_resource" "qemu_templates" {
  count = length(var.hosts)
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_rsa")
      host        = var.hosts[count.index].ip
    }
    # Bootstrap script called with private_ip of each node in the cluster
    inline = [
      "echo 'Downloading latest ubuntu image...'",
      "wget -q ${var.common.qemu_dl_root}/${var.common.qemu_template}.img -O ${var.common.qemu_template}.qcow2",
      "virt-customize -a ${var.common.qemu_template}.qcow2 --install qemu-guest-agent",
      "qm destroy ${var.hosts[count.index].vm_id} || echo 'true'",
      "while qm list | grep ${var.hosts[count.index].vm_id}; do sleep 1; done",
      "qm create ${var.hosts[count.index].vm_id} --name ci-ubuntu-template --memory 2048 --net0 virtio,bridge=vmbr0",
      "qm importdisk ${var.hosts[count.index].vm_id} ${var.common.qemu_template}.qcow2 ${var.common.template_store}",
      "qm set ${var.hosts[count.index].vm_id} --scsihw virtio-scsi-pci --scsi0 ${var.common.template_store}:${var.hosts[count.index].vm_id}/vm-${var.hosts[count.index].vm_id}-disk-0.raw",
      "qm set ${var.hosts[count.index].vm_id} --ide2 ${var.common.template_store}:cloudinit",
      "qm set ${var.hosts[count.index].vm_id} --boot c --bootdisk scsi0",
      "qm set ${var.hosts[count.index].vm_id} --serial0 socket --vga serial0",
      "qm template ${var.hosts[count.index].vm_id}"
    ]
  }
}
