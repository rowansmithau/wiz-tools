packer {
  required_plugins {
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "arch" {
  type        = string
  default     = "aarch64"
  description = "Architecture of the machine where you'd run the image"
}

variable "source_image" {
  type = map(string)
  default = {
    "distro"   = "fedora"
    "url"      = "https://mirror.aarnet.edu.au/pub/fedora/linux/releases/41/Cloud/aarch64/images/Fedora-Cloud-Base-Generic-41-1.4.aarch64.qcow2"
    "checksum" = "file:https://mirror.aarnet.edu.au/pub/fedora/linux/releases/41/Cloud/aarch64/images/Fedora-Cloud-41-1.4-aarch64-CHECKSUM"
  }
}

locals {
  qemu_binary       = "${var.arch == "aarch64" ? "qemu-system-aarch64" : "qemu-system-x86_64"}"
  accelerator       = "hvf"
  cpu_model         = "${var.arch == "aarch64" ? "cortex-a57" : "host"}"
  machine_type      = "${var.arch == "aarch64" ? "virt" : "pc"}"
  efi_boot          = "${var.arch == "aarch64" ? true : false}"
  efi_firmware_code = "${var.arch == "aarch64" ? "/opt/homebrew/share/qemu/edk2-aarch64-code.fd" : ""}"
  efi_firmware_vars = "${var.arch == "aarch64" ? "/opt/homebrew/share/qemu/edk2-arm-vars.fd" : ""}"

  source_image_url      = "${var.arch == "aarch64" ? var.source_image["url"] : replace(var.source_image["url"], "aarch64", "x86_64")}"
  source_image_checksum = "${var.arch == "aarch64" ? var.source_image["checksum"] : replace(var.source_image["checksum"], "aarch64", "x86_64")}"
}

locals {
  # used to name the VM image
  image_id_string = "wizbox-${var.source_image["distro"]}"
}

source "qemu" "wizbox" {
  iso_url      = "${local.source_image_url}"
  iso_checksum = "${local.source_image_checksum}"

  headless = true

  disk_compression = true
  disk_interface   = "virtio"
  disk_image       = true
  disk_size        = "6G"

  format       = "qcow2"
  vm_name      = "wizbox.qcow2"
  boot_command = []
  net_device   = "virtio-net"

  output_directory = pathexpand(join("/", ["~/.shikari", local.image_id_string]))

  cpus   = 8
  memory = 5120

  qemu_binary       = "${local.qemu_binary}"
  accelerator       = "hvf"
  cpu_model         = "${local.cpu_model}"
  machine_type      = "${local.machine_type}"
  efi_boot          = "${local.efi_boot}"
  efi_firmware_code = "${local.efi_firmware_code}"
  efi_firmware_vars = "${local.efi_firmware_vars}"

  qemuargs = [
    ["-cdrom", "userdata/cidata.iso"],
    ["-monitor", "none"],
    ["-no-user-config"]
  ]

  communicator     = "ssh"
  shutdown_command = "echo shikari | sudo -S shutdown -P now"
  ssh_password     = "shikari"
  ssh_username     = "shikari"

  ssh_timeout = "10m"
}

build {
  sources = ["source.qemu.wizbox"]

  provisioner "shell" {
    environment_vars = [
    ]
    inline = [
      "sudo dnf clean all",
      "sudo dnf install -y unzip wget which vim-enhanced",

      # For multicast DNS to use with socket_vmnet in Lima we use systemd-resolved. For rocky we have to install epel repo for Crudini.
      "source /etc/os-release && [[ $ID != fedora ]] && sudo dnf install -y epel-release systemd-resolved && sudo systemctl enable --now systemd-resolved",
      "sudo dnf install -y crudini $([ $(source /etc/os-release && echo $ID) != fedora ] && echo --enablerepo=epel)",
      "sudo mkdir /etc/systemd/resolved.conf.d/ && sudo crudini --ini-options=nospace --set /etc/systemd/resolved.conf.d/mdns.conf Resolve MulticastDNS yes",

      # With systemd-resolved enabled, we should use the stub-resolver for mDNS to work.
      "sudo rm /etc/resolv.conf && sudo ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf",

      # Configure Chrony to force sync everytime when the drift is more than 1 seconds
      # ref: https://chrony-project.org/faq.html#_is_chronyd_allowed_to_step_the_system_clock
      "sudo sed -i 's/^makestep.*/makestep 1 -1/g' /etc/chrony.conf",

      # Enable Docker repository and install Docker-CE
      "sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/$([ $(source /etc/os-release && echo $ID) == fedora ] && echo fedora || echo rhel)/docker-ce.repo",
      "sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "sudo dnf update -y",
      "sudo dnf clean all"
    ]
  }
}
