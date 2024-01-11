variable "cloud_id" {
  description = "Cloud"
}
variable "folder_id" {
  description = "Folder"
}
variable "zone" {
  description = "Zone"
  # Значение по умолчанию
  default = "ru-central1-a"
}
variable "public_key_path" {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}

variable "service_account_key_file" {
  description = "service_account_key_file"
}


variable "private_key_path" {
  description = "private_key"
}

variable "subnet_id" {
  description = "var.subnet_id"
}

variable "image_id" {
  description = "var.image_id"
}

variable "app_disk_image" {
  description = "Disk image for reddit app"
  default     = "app_db_disk_image"
}

variable "db_disk_image" {
  description = "var.image_id"
  default     = "db_disk_image"
}
