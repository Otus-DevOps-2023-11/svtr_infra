variable "folder_id" {
  type = string
  default = null
}

variable "service_account_key_file" {
  type = string
  default = null
}

variable "source_image_family" {
  type = string
  default = null
}

variable "ssh_username" {
  type = string
  default = null
}

variable "zone" {
  type = string
  default = null
}

source "yandex" "ubuntu16" {
  service_account_key_file = var.service_account_key_file
  folder_id = var.folder_id
  source_image_family = var.source_image_family
  image_name = "reddit-db-base-${formatdate("MM-DD-YYYY", timestamp())}"
  image_family = "reddit-db-base"
  ssh_username = var.ssh_username
  platform_id = "standard-v1"
  zone = var.zone
  use_ipv4_nat = true
}

build {
  sources = ["source.yandex.ubuntu16"]

  provisioner "shell" {
    inline = [
      "echo Waiting for apt-get to finish...",
      "a=1; while [ -n \"$(pgrep apt-get)\" ]; do echo $a; sleep 1s; a=$(expr $a + 1); done",
      "echo Done."
    ]
  }

  provisioner "shell" {
    name            = "mongodb"
    script          = "./scripts/install_mongodb.sh"
    execute_command = "sudo {{.Path}}"
  }
}
