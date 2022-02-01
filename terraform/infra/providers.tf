terraform {
  backend "s3" {
    bucket  = "zopz-terraform-state"
    key     = "homelab/terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }

  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.4"
    }
    tls = {
      version = "~> 2.1"
    }
    random = {
      version = "~> 2.2"
    }
    local = {
      version = "~> 1.4"
    }
  }
}

provider "proxmox" {
  pm_tls_insecure = true
  pm_api_url      = yamldecode(data.local_file.secrets.content).pm_api_url
  pm_user         = yamldecode(data.local_file.secrets.content).pm_user
  pm_password     = yamldecode(data.local_file.secrets.content).pm_password
}
