
source "yandex" "ubuntu16" {
  service_account_key_file = "/home/maxwell/Otus/key.json"
  folder_id = "b1g0bgapni0osi095ffl"
  source_image_family = "ubuntu-1604-lts"
  image_name = "reddit-db-${formatdate("MM-DD-YYYY", timestamp())}"
  image_family = "reddit-db"
  ssh_username = "ubuntu"
  platform_id = "standard-v1"
  subnet_id = "e9b24d2brea26rc2tc3a"
  zone = "ru-central1-a"
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