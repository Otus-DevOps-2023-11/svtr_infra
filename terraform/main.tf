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
      # ������� id ������ ���������� � ���������� ������� �������
      image_id = var.image_id	
    }
  }
  network_interface {
    # ������ id ������� default-ru-central1-a
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
    # ���� �� ���������� �����
    private_key = file(var.private_key_path)
  }
  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }
  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
  resource "yandex_vpc_network" "app-network" {
    name = "reddit-app-network"
  }

  resource "yandex_vpc_subnet" "app-subnet" {
    name           = "reddit-app-subnet"
    zone           = "ru-central1-a"
    network_id     = "${yandex_vpc_network.app-network.id}"
    v4_cidr_blocks = ["192.168.10.0/24"]
  }
}


