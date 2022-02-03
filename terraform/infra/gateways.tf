resource "proxmox_lxc" "gateway" {
  count = length(var.hosts)

  ostemplate   = "${var.common.lvm_template_dir}/${var.common.lvm_template}.tar.gz"
  ostype       = var.common.os_type
  cores        = var.gateways.cores
  memory       = var.gateways.memory
  hostname     = "gateway-${count.index}"
  vmid         = "10${count.index}"
  searchdomain = var.common.search_domain

  network {
    name     = var.common.interface_public
    bridge   = "vmbr0"
    firewall = true
    gw       = var.common.gateway
    ip       = "${cidrhost(var.common.cidr_public, count.index)}/16"
  }

  network {
    name   = var.common.interface_private
    bridge = "vmbr1"
    ip     = "${cidrhost(var.common.cidr_private, count.index)}/24"
  }

  swap     = 2048
  onboot   = true
  password = yamldecode(data.local_file.secrets.content).root_password
  rootfs {
    storage = "local-lvm"
    size    = var.gateways.disk
  }

  ssh_public_keys = join("", [
    file("~/.ssh/id_rsa.pub"),
    file("~/.ssh/terraform.pub")
  ])
  start        = true
  unprivileged = true
  target_node  = var.hosts[count.index].name

  connection {
    type        = "ssh"
    user        = "root"
    password    = yamldecode(data.local_file.secrets.content).root_password
    private_key = file("~/.ssh/terraform")
    host        = cidrhost(var.common.cidr_public, count.index)
  }

  provisioner "remote-exec" {
    inline = [
      "adduser --disabled-password --gecos \"\" terraform && usermod -aG sudo terraform",
      "usermod --password $(openssl passwd -1 ${yamldecode(data.local_file.secrets.content).user_password}}) terraform",
      "echo 'terraform ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers.d/terraform && chmod 440 /etc/sudoers.d/terraform",
      "su - terraform -c 'ssh-keygen -b 2048 -t rsa -f /home/terraform/.ssh/id_rsa -q -N \"\"'",
      "echo '${file("~/.ssh/terraform")}' > /home/terraform/.ssh/id_rsa",
      "echo '${file("~/.ssh/terraform.pub")}' > /home/terraform/.ssh/id_rsa.pub",
      "echo '${file("~/.ssh/terraform.pub")}' >> /home/terraform/.ssh/authorized_keys",
      "echo '${file("~/.ssh/id_rsa.pub")}' >> /home/terraform/.ssh/authorized_keys",
      "chown terraform:terraform /home/terraform/.ssh/authorized_keys && chmod 700 /home/terraform/.ssh/authorized_keys"
    ]
  }

  depends_on = [
    null_resource.lxc_templates
  ]
}
