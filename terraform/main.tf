provider "yandex" {
  token     = "token"
  cloud_id  = "cloud-id"
  folder_id = "folder-id"
  zone      = "ru-central1-a"
}
resource "yandex_compute_instance" "app" {
  name = "reddit-app-${count.index}"
  count = var.app_count
  resources {
    cores  = 2
    memory = 16
  }
  boot_disk {
    initialize_params {
      # ”казать id образа созданного в предыдущем домашем задании
      image_id = var.image_id	
    }
  }
  network_interface {
    # ”казан id подсети default-ru-central1-a
    subnet_id = var.subnet_id
    nat       = true
  }
  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

  connection {
    type  = "ssh"
    host  = self.network_interface.0.nat_ip_address
    user  = "ubuntu"
    agent = false
    # путь до приватного ключа
    private_key = file(var.private_key_path)
  }
  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }
  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
}


