terraform {
  backend "s3" {
    endpoint = "storage.yandexcloud.net"
    bucket   = "terraform2"
    region   = "ru-central1"
    key      = "prod/terraform.tfstate"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
