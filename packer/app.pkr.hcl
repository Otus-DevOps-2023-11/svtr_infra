source "yandex" "app.pkr.hcl" {
  image_name = "reddit-base-${formatdate("MM-DD-YYYY", timestamp())}"
}


build {
  sources = ["source.yandex.app.pkr.hcl"]


  provisioner "shell" {
    name            = "ruby"
    script          = "./scripts/install_ruby.sh"
    execute_command = "sudo {{.Path}}"
  }
}