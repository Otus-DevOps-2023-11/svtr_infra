variable "cloud_id" {
  description = "Cloud"
  default     = ""
}
variable "folder_id" {
  description = "Folder"
}
variable "zone" {
  description = "Zone"
  # �������� �� ���������
  default = "ru-central1-a"
}
variable "public_key_path" {
  # �������� ����������
  description = "~/.ssh/yc-user.pub"
}
variable "private_key_path" {
  # �������� ���������� private key
  description = "Path to the private key"
}
variable "image_id" {
  description = "Disk image"
}
variable "subnet_id" {
  description = "Subnet"
}
variable "service_account_key_file" {
  default = "/home/maxwell/Otus/key.json"
}
variable app_disk_image {
  description = "Disk image for reddit app"
  default = "reddit-app"
}
variable db_disk_image {
description = "Disk image for reddit db"
default = "reddit-db-base"
}
