source "yandex" "ubuntu16" {
  image_name = "reddit-base-${formatdate("MM-DD-YYYY", timestamp())}"
}


build {
  sources = ["source.yandex.ubuntu16"]


  provisioner "shell" {
    name            = "ruby"
    script          = "./scripts/install_ruby.sh"
    execute_command = "sudo {{.Path}}"
  }


  provisioner "shell" {
    name            = "mongodb"
    script          = "./scripts/install_mongodb.sh"
    execute_command = "sudo {{.Path}}"
  }
}