resource "random_shuffle" "kube_worker_hosts" {
  input        = var.hosts.*.name
  result_count = var.workers.count
}

resource "proxmox_vm_qemu" "kube_worker" {
  count = var.workers.count

  name        = "worker-${count.index}"
  target_node = random_shuffle.kube_worker_hosts.result[count.index]
  agent       = 1
  clone       = var.common.clone
  os_type     = "cloud-init"
  vmid        = "30${count.index}"
  memory      = var.workers.memory
  cores       = var.workers.cores
  ipconfig0   = "ip=${cidrhost(var.common.cidr_public, "10${count.index}")}/16,gw=${var.common.gateway}"
  ipconfig1   = "ip=${cidrhost(var.common.cidr_private, "10${count.index}")}/16"
  bootdisk    = "scsi0"
  scsihw      = "virtio-scsi-pci"

  vga {
    type = "qxl"
  }

  network {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = true
  }

  network {
    model  = "virtio"
    bridge = "vmbr1"
  }

  disk {
    type    = "scsi"
    storage = "local-lvm"
    size    = var.workers.disk
  }

  serial {
    id   = 0
    type = "socket"
  }

  ciuser     = "terraform"
  cipassword = yamldecode(data.local_file.secrets.content).user_password
  sshkeys = join("", [
    file("~/.ssh/id_rsa.pub"),
    file("~/.ssh/terraform.pub")
  ])

  depends_on = [
    proxmox_lxc.gateway
  ]

  connection {
    type        = "ssh"
    user        = "terraform"
    password    = yamldecode(data.local_file.secrets.content).user_password
    private_key = yamldecode(data.local_file.secrets.content).terraform_key
    host        = cidrhost(var.common.cidr_public, "10${count.index}")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo usermod --password $(openssl passwd -1 ${yamldecode(data.local_file.secrets.content).root_password}}) root",
      "ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N \"\"",
      "echo '${file("~/.ssh/terraform.pub")}' > ~/.ssh/id_rsa",
      "echo '${file("~/.ssh/terraform.pub")}' > ~/.ssh/id_rsa.pub",
    ]
  }
}
