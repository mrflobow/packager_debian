packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "iso_file" {
  type    = string
  default = "local:iso/debian-11.6.0-amd64-netinst.iso"
}

variable "cloudinit_storage_pool" {
  type    = string
  default = "local"
}

variable "cores" {
  type    = string
  default = "2"
}

variable "disk_format" {
  type    = string
  default = "raw"
}

variable "disk_size" {
  type    = string
  default = "20G"
}

variable "disk_storage_pool" {
  type    = string
  default = "data"
}

variable "disk_storage_pool_type" {
  type    = string
  default = "lvm"
}

variable "memory" {
  type    = string
  default = "2048"
}

variable "network_vlan" {
  type    = string
  default = ""
}

variable "proxmox_api_token" {
  type      = string
  sensitive = true
}

variable "proxmox_api_user" {
  type = string
}

variable "proxmox_host" {
  type = string
}

variable "proxmox_node" {
  type = string
}

variable "vm_id" {
  type = string
  default = "5000"
}

source "proxmox-iso" "debian-11" {
  proxmox_url              = "https://${var.proxmox_host}/api2/json"
  insecure_skip_tls_verify = true
  username                 = var.proxmox_api_user
  token                 = var.proxmox_api_token

  template_description = "Debian 11 cloud-init template. Built on ${formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())}"
  node                 = var.proxmox_node
  network_adapters {
    bridge   = "vmbr0"
    firewall = true
    model    = "virtio"
    vlan_tag = var.network_vlan
  }
  disks {
    disk_size         = var.disk_size
    format            = var.disk_format
    io_thread         = true
    storage_pool      = var.disk_storage_pool
    storage_pool_type = var.disk_storage_pool_type
    type              = "scsi"
  }
  scsi_controller = "virtio-scsi-single"

  iso_file       = var.iso_file
  http_directory = "./"
  boot_wait      = "10s"
  boot_command   = ["<esc><wait>auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg<enter>"]
  unmount_iso    = true

  cloud_init              = true
  cloud_init_storage_pool = var.cloudinit_storage_pool

  vm_name  = "debian-11.6-cloudinit"
  memory   = var.memory
  cores    = var.cores
  sockets  = "1"

  vm_id = var.vm_id

  ssh_password = "packer"
  ssh_username = "root"
}

build {
  sources = ["source.proxmox-iso.debian-11"]

  provisioner "file" {
    destination = "/etc/cloud/cloud.cfg"
    source      = "cloud.cfg"
  }
}
