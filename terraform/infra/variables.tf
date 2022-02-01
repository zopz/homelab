variable "common" {
  type = map(string)
  default = {
    template_store    = "local"
    lvm_template      = "ubuntu-20.04-standard_20.04-1_amd64"
    lvm_template_dir  = "local:vztmpl"
    qemu_dl_root      = "http://cloud-images.ubuntu.com/focal/current"
    qemu_template     = "focal-server-cloudimg-amd64"
    os_type           = "ubuntu"
    clone             = "ci-ubuntu-template"
    nameserver        = "10.100.1.0"
    gateway           = "10.100.1.0"
    interface_public  = "eth0"
    cidr_public       = "10.100.100.0/24"
    interface_private = "eth1"
    cidr_private      = "172.30.1.0/24"
  }
}

variable "hosts" {
  type = list(any)
  default = [
    {
      name  = "zp-r710-1",
      ip    = "10.100.2.1",
      vm_id = "9000"
    },
    {
      name  = "zp-r620-1",
      ip    = "10.100.2.2",
      vm_id = "9001"
    }
  ]
}

variable "gateways" {
  type = map(any)
  default = {
    count  = 2
    cores  = 2
    memory = 2048
    disk   = "16G"
  }
}

variable "masters" {
  type = map(any)
  default = {
    count  = 3
    cores  = 2
    memory = 2048
    disk   = "15564M"
  }
}

variable "workers" {
  type = map(any)
  default = {
    count  = 3
    cores  = 4
    memory = 8192
    disk   = "81100M"
  }
}
