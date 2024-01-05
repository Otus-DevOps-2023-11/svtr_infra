# ДЗ Знакомство с облачной инфраструктурой Yandex.Cloud

```css
testapp_IP = 51.250.82.246
testapp_port = 9292
```
# ДЗ №5 "Сборка образов VM при помощи Packer"
1.устанговка  Packer - дистрибутив взат с яндекс cloud

2.Получаем folder-id и создаем сервисный аккаунт в Yandex.Cloud
```css
$ yc config list | grep folder-id
$ SVC_ACCT="appuser"
$ FOLDER_ID="<полученный folder-id>"
$ yc iam service-account create --name $SVC_ACCT --folder-id $FOLDER_ID
```

3.Выдаем сервисному аккаунту права **editor**

```css
$ ACCT_ID=$(yc iam service-account get $SVC_ACCT | \
grep ^id | \
awk '{print $2}')
$ yc resource-manager folder add-access-binding --id $FOLDER_ID \
--role editor \
--service-account-id $ACCT_ID
```
4.Создаем **IAM** key файл за пределами git репозитория
```css
$ yc iam key create --service-account-id $ACCT_ID --output ~/key/key.json
```
5.Создаем файл Packer шаблона ubuntu16.json по примеру. 
Была ошибка что при валидации что yandex не известен
Установлен плагин с яндекс клоуда 

6.Описываем в шаблоне ubuntu16.json секцию **Builder**
```css
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "{{user `service_account_key_file_path`}}",
            "folder_id": "{{user `folder_id`}}",
            "source_image_family": "{{user `source_image_family`}}",
            "image_name": "reddit-base-{{timestamp}}",
            "image_family": "reddit-base",
            "ssh_username": "ubuntu",
            "platform_id": "{{user `platform_id`}}",
            "use_ipv4_nat": "true",
            "instance_cores": "{{user `instance_cores`}}",
            "instance_mem_gb": "{{user `instance_mem_gb`}}",
            "instance_name": "{{user `instance_name`}}"
        }
```
7.Добавляем в packer шаблон секцию **Provisioners**
```css
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
```
8.В каталоге **packer** создаем каталог **scripts** и копируем туда скрипты install_ruby.sh и install_mongodb.sh

9.Выполняем синтакическую проверку packer шаблона на ошибки
```css
$ packer validate ./ubuntu16.json
```
10.Запускаем сборку образа
```css
$ packer build ./ubuntu16.json
```
11.Необходимо в секцию **Biulders** шаблона ubuntu16.json добавить NAT
```css
"use_ipv4_nat": "true"
``` 
Ошибка _Quota limit vpc.networks.count exceeded_, решается удалением сети , которая была привязана к каталогу default , такак лимит 2

12.Создание ВМ из созданного образа через web Yandex.Cloud
    Выбор образа/загрузочного диска - Пользовательские - Образ
13.Вход в ВМ по ssh
```css
$ ssh -i ~/.ssh/appuser appuser@<публичный IP машины>
```
14.Проверка образа и установка приложения
```css
$ sudo apt-get update
$ sudo apt-get install -y git
$ git clone -b monolith https://github.com/express42/reddit.git
$ cd reddit && bundle install
$ puma -d
```
15.Параметризирование шаблона  
    Создан файл template.json с параметрами, .json добавлен в .gitignore  
    На основе template.json создан файл template.json.example с вымышленными значениями
```css
{
    "folder_id": "id",
    "source_image_family": "ubuntu-1604-lts",
    "service_account_key_file_path": "/path/to/key.json",
    "platform_id": "standard-v1",
    "instance_cores": "2",
    "instance_mem_gb": "2",
    "instance_name": "reddit-app-instance"
}
```
# ДЗ №6 "Практика IaC с использованием Terraform"
1.Создаем новую ветку в репозитории
```css
$ git checkout -b terraform-1
``` 
2.Скачиваем бинарный файл terraform версии 0.12.8, распаковываем архив и помещаем бинарный файл terraform в директорию из переменной $PATH, проверяем версию terraform
```css
$ wget https://releases.hashicorp.com/terraform/0.12.8/terraform_0.12.8_linux_386.zip
$ unzip terraform_0.12.8_linux_386.zip -d terraform_0.12.8
$ cp terraform_0.12.8/terraform /usr/local/bin
$ terraform -v
``` 

3.Создаем директорию **terraform** в проекте, внутри нее создаем главный конфигурационный файл **main.tf**
```css
$ mkdir terraform
$ touch terraform/main.tf
```


4.Узнаем значения token, cloud-id и folder-id через команду **yc config list** и записываем их в **main.tf**
```css
provider "yandex" {
  token     = "token"
  cloud_id  = "cloud-id"
  folder_id = "folder-id"
  zone      = "ru-central1-a"
} 
```

5.Создаем через web интерфейс новый сервисный аккаунт с названием terraform и даем ему роль editor

6.Экспортируем ключ сервисного аккаунта и устанавливаем его по умолчанию для использования
```css
$ yc iam key create --service-account-name terraform --output ~/terraform_key.json
$ yc config set service-account-key ~/terraform_key.json
```

7.Для загрузки модуля провайдера Yandex в директории terraform выполняем команду
```css
$ terraform init
```

8.Добавляем в **main.tf** ресурс по созданию инстанса
   image_id берем из вывода команды
```css
yc compute image list
```
subnet_id из вывода команды
```css
`x`
```

```css
resource "yandex_compute_instance" "app" {
  name = "reddit-app"

  resources {
    cores  = 1
    memory = 2
  }

  boot_disk {
    initialize_params {
      # Указать id образа созданного в предыдущем домашем задании
      image_id = "***"
    }
  }

  network_interface {
    # Указан id подсети default-ru-central1-a
    subnet_id = "***"
    nat       = true
  }
}
```

9.Для возможности поделючения к ВМ по ssh добавляем в **main.tf** информацию о публичном ключе
```css
resource "yandex_compute_instance" "app" {
...
  metadata = {
  ssh-keys = "ubuntu:${file("~/.ssh/appuser.pub")}"
  }
...
}
```

10.Смотрим план изменений перед создание ресурса
```css
$ terraform plan
```

11.Запускаем инстанс ВМ
```css
$ terraform apply
```

12.Для выходных переменных создаем в директории **terraform** отделный файл **outputs.tf**
```css
$ touch outputs.tf
```

с следующим содержимым:
```css
output "external_ip_address_app" {
value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
```

13.В основной конфиг **main.tf** добавляем секцию с provisioner для копирования с локальной машины на ВМ Unit файла
```css
provisioner "file" {
  source = "files/puma.service"
  destination = "/tmp/puma.service"
}
```

14.Создаем директорию files
```css
$ mkdir files
```

В ней создаем Unit файл
```css
$ touch puma.service
```

Заполняем файл следующим содержимым
```css
[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/reddit
ExecStart=/bin/bash -lc 'puma'
Restart=always

[Install]
WantedBy=multi-user.target
```

15.В основной конфиг **main.tf** добавляем секцию с provisioner для деплоя приложения
```css
provisioner "remote-exec" {
  script = "files/deploy.sh"
}
```

16.В директории **files** создаем скрипт **deploy.sh**
```css
$ touch files/deploy.sh
```
с следующим содержимым
```css
#!/bin/bash
set -e
APP_DIR=${1:-$HOME}
sudo apt update
sleep 30
sudo apt-get install -y git
git clone -b monolith https://github.com/express42/reddit.git $APP_DIR/reddit
cd $APP_DIR/reddit
bundle install
sudo mv /tmp/puma.service /etc/systemd/system/puma.service
sudo systemctl start puma
sudo systemctl enable puma
```

17.В основной конфиг **main.tf**, перед определения провижинеров, добавляем параметры подключения провиженеров к ВМ
```css
connection {
  type = "ssh"
  host = yandex_compute_instance.app.network_interface.0.nat_ip_address
  user = "ubuntu"
  agent = false
  # путь до приватного ключа
  private_key = file("~/.ssh/appuser")
  }
```

18.Через команду __terraform taint__ помечаем ВМ для его дальнейшего пересоздания
```css
$ terraform taint yandex_compute_instance.app
```

19.Проверяем план изменений
```css
$ terraform plan
```

и запускаем пересборку ВМ
```css
$ terraform apply
```

20.Для определения входных переменных создадим в директории **terraform** файл **variables.tf** с следующим содержимым:
```css
variable cloud_id{
  description = "Cloud"
}
variable folder_id {
  description = "Folder"
}
variable zone {
  description = "Zone"
  # Значение по умолчанию
  default = "ru-central1-a"
}
variable public_key_path {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}
variable image_id {
  description = "Disk image"
}
variable subnet_id{
  description = "Subnet"
}
variable service_account_key_file{
  description = "key .json"
}
```

21.В **maint.tf** переопределим параметры через input переменные
```css
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

  boot_disk {
    initialize_params {
      # Указать id образа созданного в предыдущем домашем задании
      image_id = var.image_id
    }
  }

  network_interface {
    # Указан id подсети default-ru-central1-a
    subnet_id = var.subnet_id
    nat       = true
  }

  metadata = {
  ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
```

22.Для определения самих переменных создадим файл **terraform.tfvars**
```css
$ touch terraform.tfvars
```

с следующим содержимым (реальные значения скрыты звездочками) и с указанием переменных для публичного и приватного ключа
```css
cloud_id                 = "***"
folder_id                = "***"
zone                     = "ru-central1-a"
image_id                 = "***"
public_key_path          = "~/.ssh/appuser.pub"
private_key_path         = "~/.ssh/appuser"
subnet_id                = "***"
service_account_key_file = "~/key/terraform_key.json"       
```

23.Удалим предыдущий созданный инстанс и создадим новый
```css
$ terraform destroy
$ terraform plan
$ terraform apply
```

24.После сборки инстанса проверяем через браузер, введя в строке браузера значение полученное в external_ip_address_app после сборки интанса с указанием порта 9292

25.Добавим в **.gitignore** следующие исключения
```css
*.tfstate
*.tfstate.*.backup
*.tfstate.backup
*.tfvars
.terraform/
.terraform/files/appuser.pub
```

## Самостоятельное задание
1.Определяем input переменную для приватного ключа в **terraform.tfvars**
```css
private_key_path         = "~/.ssh/appuser"
```
Определяем input переменную для приватного ключа в **variables.tf**
```css
variable private_key_path {
  # Описание переменной
  description = "Path to the private key used for ssh access"
}
```
Вносим переменную приватного ключа в блок conenction файла **main.tf**
```css
private_key = file(var.private_key_path)
```
2.Определяем input переменную для задания зоны ресурса "yandex_compute_instance" "app"
```css
resource "yandex_compute_instance" "app" {
  name = "reddit-app"
  zone = var.zone

  resources {
    cores  = 2
    memory = 2
  }
```

3.Форматируем все конфиги terraform через команду
```css
$ terraform fmt
```

4.Ввиду добавления файла terraform.tfvars в .gitignore, делаем копию файла с переменными с другим именем и заменяем реальные значения на звездочки
```css
$ cp terraform.tfvars terraform.tfvars.example
```

новое содержимое файла
```css
cloud_id                 = "***"
folder_id                = "***"
zone                     = "ru-central1-a"
image_id                 = "***"
public_key_path          = "/path/to/key.pub"
private_key_path         = "/path/to/key"
subnet_id                = "***"
service_account_key_file = "/path/to/key.json"
```