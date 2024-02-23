source "yandex" "db.pkr.hcl" {
  image_name = "reddit-base-${formatdate("MM-DD-YYYY", timestamp())}"
}


build {
  sources = ["source.yandex.db.pkr.hcl"]


  provisioner "shell" {
    name            = "mongodb"
    script          = "./scripts/install_mongodb.sh"
    execute_command = "sudo {{.Path}}"
  }
}