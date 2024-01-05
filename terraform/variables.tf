variable "cloud_id" {
  description = "Cloud"
}

variable "folder_id" {
  description = "Folder"
}

variable "zone" {
  description = "Zone"
  default     = ""
}

variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}

variable "image_id" {
  description = "Disk image"
}

variable "network_id" {
  description = "Network ID"
}

variable "subnet_id" {
  description = "Subnet ID"
}

variable "service_account_key_file" {
  description = "key.json"
}

variable "privite_key" {
  description = "privite_key"
}
variable private_key_path {
  # Описание переменной
  description = "Path to the private key used for ssh access"
}
variable "app_count" {
  description = "Number of app instances"
  default     = 1
}
