# ДЗ Знакомство с облачной инфраструктурой Yandex.Cloud
testapp_IP = 51.250.82.246
testapp_port = 9292



# ДЗ №5 "Сборка образов VM при помощи Packer"

1. устанговка  Packer - дистрибутив взат с яндекс cloud

2. Получаем folder-id и создаем сервисный аккаунт в Yandex.Cloud
```css
$ yc config list | grep folder-id
$ SVC_ACCT="appuser"
$ FOLDER_ID="<полученный folder-id>"
$ yc iam service-account create --name $SVC_ACCT --folder-id $FOLDER_ID
```

3. Выдаем сервисному аккаунту права **editor**

```css
$ ACCT_ID=$(yc iam service-account get $SVC_ACCT | \
grep ^id | \
awk '{print $2}')
$ yc resource-manager folder add-access-binding --id $FOLDER_ID \
--role editor \
--service-account-id $ACCT_ID
```
4.  Создаем **IAM** key файл за пределами git репозитория
```css
$ yc iam key create --service-account-id $ACCT_ID --output ~/key/key.json
```
5. Создаем файл Packer шаблона ubuntu16.json по примеру. 
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
7. Добавляем в packer шаблон секцию **Provisioners**
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
8. В каталоге **packer** создаем каталог **scripts** и копируем туда скрипты install_ruby.sh и install_mongodb.sh

9. Выполняем синтакическую проверку packer шаблона на ошибки
```css
$ packer validate ./ubuntu16.json
```
10. Запускаем сборку образа
```css
$ packer build ./ubuntu16.json
```
11. Необходимо в секцию **Biulders** шаблона ubuntu16.json добавить NAT
```css
"use_ipv4_nat": "true"
``` 
ошибка _Quota limit vpc.networks.count exceeded_, решается удалением сети , которая была привязана к каталогу default , такак лимит 2

12. Создание ВМ из созданного образа через web Yandex.Cloud
    Выбор образа/загрузочного диска - Пользовательские - Образ
13. Вход в ВМ по ssh
```css
$ ssh -i ~/.ssh/appuser appuser@<публичный IP машины>
```
14. Проверка образа и установка приложения
```css
$ sudo apt-get update
$ sudo apt-get install -y git
$ git clone -b monolith https://github.com/express42/reddit.git
$ cd reddit && bundle install
$ puma -d
```
15. Параметризирование шаблона  
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

18. Построение bake-образа (задание с⭐)  
    На основе шаблона ubuntu16.json создан шаблон immutable.json с добавлением в секцию **provisioners** скрипта на деплой и запуск приложения
```css
{
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "{{user `service_account_key_file_path`}}",
            "folder_id": "{{user `folder_id`}}",
            "source_image_family": "{{user `source_image_family`}}",
            "image_name": "reddit-full-{{timestamp}}",
            "image_family": "reddit-full",
            "ssh_username": "ubuntu",
            "platform_id": "{{user `platform_id`}}",
            "use_ipv4_nat": "true",
            "instance_cores": "{{user `instance_cores`}}",
            "instance_mem_gb": "{{user `instance_mem_gb`}}",
            "instance_name": "{{user `instance_name`}}"
        }
    ],
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
        },
        {
            "type": "shell",
            "script": "files/deploy.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}
```

19. Описываем скрипт deploy.sh с установкой зависимостей и автозапуском приложения при помощи systemd unit после старта ОС
```css
#!/bin/bash
apt update
apt-get install -y git
mkdir /var/run/my-reddit-app && mkdir /opt/my-reddit-app
git clone -b monolith https://github.com/express42/reddit.git /opt/my-reddit-app
cd /opt/my-reddit-app
bundle install

cat > /etc/systemd/system/reddit-app.service << EOF
[Unit]
Description=My Reddit App
After=network.target
After=mongod.service

[Service]
Type=simple
PIDFile=/var/run/my-reddit-app/my-reddit.pid
WorkingDirectory=/opt/my-reddit-app

ExecStart=/usr/local/bin/puma

[Install]
WantedBy=multi-user.target
EOF

systemctl enable reddit-app.service
systemctl start reddit-app.service
```

20. Автоматизация создания ВМ (задание со⭐)  
    Создаем скрипт create-reddit-vm.sh для автоматического создани ВМ через Yandex.Cloud CLI с последующим запуском скрипта на установку зависимостей, деплоя приложения и запуска приложения с помощью systemd unit
```css
#!/bin/bash
yc compute instance create \
  --name reddit-full \
  --hostname reddit-full \
  --cores 2 \
  --core-fraction 5 \
  --memory=2 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
  --network-interface subnet-name=otus,nat-ip-version=ipv4 \
  --metadata serial-port-enable=1 \
  --metadata-from-file user-data=./install-dependencies-deploy-app.yaml
```

Создаем скрипт install-dependencies-deploy-app.yaml с набором комманд для деплоя приложения и запуска приложения через systemd unit
```css
#cloud-config
users:
  - name: appuser
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5r+a3wgOx1nQ5Gawxw+qpnvOFsdKg5XbhiJtt81N9soTZGiPtxoSbnTBnBDA9UoDWKxm1XAGIqzaASJNBnsDdf6sYXVLvC0QbjgF8205CWrErk9+6o7qy7wffJCAv7ZuIE03dUMYL9Ddv+OgcfyzGWJ+ChbHwwfYPq4QukbrmL70eaw09wr4bEQU/MPSPHcWZqiSz0reWYz9nqh3P6rjyiYyeWoa8Bm871BV/gkxLgxHqqjIqGFbq/reDxxSAdNumhIsHksMERyxnbA1SGh95XTSPy8LAfad/v2/aULYwnwIemEa5KIKgWW5od4QWA4B0dlyVba8NGiEl09VoJGpX appuser
runcmd:
  - apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
  - echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list
  - apt update
  - apt install -y mongodb-org
  - systemctl start mongod
  - systemctl enable mongod
  - apt install -y ruby-full ruby-bundler build-essential apt-transport-https ca-certificates
  - apt update
  - apt install -y git
  - mkdir /var/run/my-reddit-app && mkdir /opt/my-reddit-app
  - git clone -b monolith https://github.com/express42/reddit.git /opt/my-reddit-app
  - cd /opt/my-reddit-app
  - bundle install
  - echo "[Unit]" >> /etc/systemd/system/reddit-app.service
  - echo "Description=My Reddit App" >> /etc/systemd/system/reddit-app.service
  - echo "After=network.target" >> /etc/systemd/system/reddit-app.service
  - echo "After=mongod.service" >> /etc/systemd/system/reddit-app.service
  - echo "[Service]" >> /etc/systemd/system/reddit-app.service
  - echo "Type=simple" >> /etc/systemd/system/reddit-app.service
  - echo "PIDFile=/var/run/my-reddit-app/my-reddit.pid" >> /etc/systemd/system/reddit-app.service
  - echo "WorkingDirectory=/opt/my-reddit-app" >> /etc/systemd/system/reddit-app.service
  - echo "ExecStart=/usr/local/bin/puma" >> /etc/systemd/system/reddit-app.service
  - echo "[Install]" >> /etc/systemd/system/reddit-app.service
  - echo "WantedBy=multi-user.target" >> /etc/systemd/system/reddit-app.service
  - systemctl enable reddit-app.service
  - systemctl start reddit-app.service
```

# ДЗ №6 "Практика IaC с использованием Terraform"

1. Создаем новую ветку в репозитории
```css
$ git checkout -b terraform-1
``` 

2. Скачиваем бинарный файл terraform версии 0.12.8, распаковываем архив и помещаем бинарный файл terraform в директорию из переменной $PATH, проверяем версию terraform
```css
$ wget https://releases.hashicorp.com/terraform/0.12.8/terraform_0.12.8_linux_386.zip
$ unzip terraform_0.12.8_linux_386.zip -d terraform_0.12.8
$ cp terraform_0.12.8/terraform /usr/local/bin
$ terraform -v
``` 

3. Создаем директорию **terraform** в проекте, внутри нее создаем главный конфигурационный файл **main.tf**
```css
$ mkdir terraform
$ touch terraform/main.tf
```


4. Узнаем значения token, cloud-id и folder-id через команду **yc config list** и записываем их в **main.tf**
```css
provider "yandex" {
  token     = "token"
  cloud_id  = "cloud-id"
  folder_id = "folder-id"
  zone      = "ru-central1-a"
} 
```

5. Создаем через web интерфейс новый сервисный аккаунт с названием terraform и даем ему роль editor

6. Экспортируем ключ сервисного аккаунта и устанавливаем его по умолчанию для использования
```css
$ yc iam key create --service-account-name terraform --output ~/terraform_key.json
$ yc config set service-account-key ~/terraform_key.json
```

7. Для загрузки модуля провайдера Yandex в директории terraform выполняем команду
```css
$ terraform init
```

8. Добавляем в **main.tf** ресурс по созданию инстанса
   image_id берем из вывода команды
```css
yc compute image list
```
subnet_id из вывода команды
```css
yc vpc network --id <id сети> list-subnets
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

9. Для возможности поделючения к ВМ по ssh добавляем в **main.tf** информацию о публичном ключе
```css
resource "yandex_compute_instance" "app" {
...
  metadata = {
  ssh-keys = "ubuntu:${file("~/.ssh/appuser.pub")}"
  }
...
}
```

10. Смотрим план изменений перед создание ресурса
```css
$ terraform plan
```

11. Запускаем инстанс ВМ
```css
$ terraform apply
```

12. Для выходных переменных создаем в директории **terraform** отделный файл **outputs.tf**
```css
$ touch outputs.tf
```

с следующим содержимым:
```css
output "external_ip_address_app" {
value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
```

13. В основной конфиг **main.tf** добавляем секцию с provisioner для копирования с локальной машины на ВМ Unit файла
```css
provisioner "file" {
  source = "files/puma.service"
  destination = "/tmp/puma.service"
}
```

14. Создаем директорию files
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

13. В основной конфиг **main.tf** добавляем секцию с provisioner для деплоя приложения
```css
provisioner "remote-exec" {
  script = "files/deploy.sh"
}
```

14. В директории **files** создаем скрипт **deploy.sh**
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

15. В основной конфиг **main.tf**, перед определения провижинеров, добавляем параметры подключения провиженеров к ВМ
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

16. Через команду __terraform taint__ помечаем ВМ для его дальнейшего пересоздания
```css
$ terraform taint yandex_compute_instance.app
```

17. Проверяем план изменений
```css
$ terraform plan
```

и запускаем пересборку ВМ
```css
$ terraform apply
```

18. Для определения входных переменных создадим в директории **terraform** файл **variables.tf** с следующим содержимым:
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

19. В **maint.tf** переопределим параметры через input переменные
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

20. Для определения самих переменных создадим файл **terraform.tfvars**
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

21. Удалим предыдущий созданный инстанс и создадим новый
```css
$ terraform destroy
$ terraform plan
$ terraform apply
```

22. После сборки инстанса проверяем через браузер, введя в строке браузера значение полученное в external_ip_address_app после сборки интанса с указанием порта 9292

23. Добавим в **.gitignore** следующие исключения
```css
*.tfstate
*.tfstate.*.backup
*.tfstate.backup
*.tfvars
.terraform/
.terraform/files/appuser.pub
```

## Самостоятельное задание
1. Определяем input переменную для приватного ключа в **terraform.tfvars**
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
2. Определяем input переменную для задания зоны ресурса "yandex_compute_instance" "app"
```css
resource "yandex_compute_instance" "app" {
  name = "reddit-app"
  zone = var.zone

  resources {
    cores  = 2
    memory = 2
  }
```

3. Форматируем все конфиги terraform через команду
```css
$ terraform fmt
```

4. Ввиду добавления файла terraform.tfvars в .gitignore, делаем копию файла с переменными с другим именем и заменяем реальные значения на звездочки
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

## Задания с ⭐
Создание HTTP балансировщика

1. Создаем файл **lb.tf** в котором опишем HTTP балансировщик
```css
$ touch lb.tr
```
2. Создадим целевую группу, в которую балансировщик будет распределять нагрузку  
   В группу добавляем ip хоста создаваемый в конфиге **main.tf** через переменную __yandex_compute_instance.app.network_interface.0.ip_address__
```css
resource "yandex_lb_target_group" "my-target-group" {
  name      = "my-target-group"
  region_id = var.region

  target {
    subnet_id = var.subnet_id
    address   = "${yandex_compute_instance.app.network_interface.0.ip_address}"
  }
}
```
3. Создаем сам балансировщик с указанием на целевую группу, добавляем обработчик (listener) с указанием на каком порту слушать соединение (80) и куда в целевую группу передавать (9292)
```css
resource "yandex_lb_network_load_balancer" "my-external-lb" {
  name = "my-network-lb"

  listener {
    name = "my-listener"
    port = 80
    target_port = 9292
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = "${yandex_lb_target_group.my-target-group.id}"

    healthcheck {
      name = "http"
      http_options {
        port = 9292
        path = "/"
      }
    }
  }
}
```

4. В output переменные (outputs.tf) добавляем вывод внешнего адреса балансировщика
```css
output "external_ip_address_lb" {
  value = yandex_lb_network_load_balancer.my-external-lb.listener.*.external_address_spec[0].*.address
}
```

5. Проверяем список изменений и запускаем деплой балансировщика
```css
$ terraform plan
$ terraform apply
```

6. Проверяем работу балансировщика введя в cтроке адреса web браузера **<полученный ip балансировщика>:80**


## Задания с ⭐
Организация второго инстанса с приложением

1. В основном шаблоне **main.tf** добавляем создание второго инстанса app2 с именем reddit-app2 и деплоем приложения
```css
resource "yandex_compute_instance" "app2" {
  name = "reddit-app2"
  zone = var.zone

  resources {
    cores  = 2
    memory = 2
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

  connection {
    type  = "ssh"
    host  = yandex_compute_instance.app2.network_interface.0.nat_ip_address
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
```

2. В шаблоне **lb.tf** в таргет группу добавляем запись о втором хосте назначения
```css
  target {
    subnet_id = var.subnet_id
    address   = "${yandex_compute_instance.app2.network_interface.0.ip_address}"
  }
```

3. В выходные переменные **outputs.tf** добавляем вывод ip второго хоста
```css
output "external_ip_address_app2" {
  value = yandex_compute_instance.app2.network_interface.0.nat_ip_address
}
```

4. Вопрос из ДЗ:
>Какие проблемы вы видите в такой конфигурации приложения?

Ответ: В данной схеме все инстансы с приложением, включая и балансировщик находятся в одном регионе. В случае падения сети в этом регионе теряем всю схему отказоустойчивости. Целесообразнее инстансы с приложением размещать в разных регионах.

## Задания с ⭐
Организация второго инстанса через переменные

1. В **variables.tf** добавляем описание переменной для количества инстансов
```css
variable instances_count {
  description = "Count of instances"
  default     = 1
}
```

2. В **terraform.tfvars** добавлем значение переменной по условию задачи
```css
instances_count          = "2"
```

3. Удалаяем блок с кодом о втором инстансе из **main.tf** и добавялем переменную count, редактируем переменную name
```css
resource "yandex_compute_instance" "app" {
  count = var.instances_count
  name = "reddit-app${count.index}"
  zone = var.zone
...
}
```

в блоке conenction правим значение host
```css
host  = self.network_interface.0.nat_ip_address
```

4. В **lb.tf** правим блок target делая его dynamic
```css
  dynamic "target" {
    for_each  = "${yandex_compute_instance.app.*.network_interface.0.ip_address}"
    content {
      subnet_id = var.subnet_id
      address   = target.value
    }
  }
```

5. Проверка получившейся конфигурации на ошибки, просмотр плана изменений и запуск
```css
$ terraform plan
$ terraform apply
```
# ДЗ №7 "Принципы организации инфраструктурного кода и работа над инфраструктурой в команде на примере Terraform"

1. Создаем новую ветку
```css
$ git checkout -b terraform-2
```

2. Устанавливаем в **variables.tf** количество инстансов app равным 1
```css
variable instances_count {
  description = "Count of instances"
  default     = 1
}
```

3. Переносим файл **lb.tf** в **terraform/files**
```css
$ mv lb.tf terraform/files
```

4. В **main.tf** определяем ресурсы yandex_vpc_network и yandex_vpc_subnet
```css
resource "yandex_vpc_network" "app-network" {
  name = "reddit-app-network"
}

resource "yandex_vpc_subnet" "app-subnet" {
  name           = "reddit-app-subnet"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.app-network.id}"
  v4_cidr_blocks = ["192.168.10.0/24"]
}
```

5. Применим изменения
```css
$ terraform apply
```

6. В файле **main.tf** в конфигурации vm ссылаемся на атрибуты ресурса который создает IP
```css
network_interface {
  subnet_id = yandex_vpc_subnet.app-subnet.id
  nat = true
}
```

7. Пересоздаем инстанс, что бы увидеть очередность создания ресурсов зависимых друг от друга
```css
$ terraform destroy
$ terraform plan
$ terraform apply
```

8. Вынесение БД и APP на отдельный инстанс VM

В директории **packer** создаем новые шаблоны **db.json** и **app.json** на основе шаблона **ubuntu16.json** и убираем все не нужное
```css
$ cp ../packer/ubuntu16.json ../packer/db.json
$ cp ../packer/ubuntu16.json ../packer/app.json
```

Финальное содержимое шаблона **db.json**
```css
{
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "{{user `service_account_key_file_path`}}",
            "folder_id": "{{user `folder_id`}}",
            "source_image_family": "{{user `source_image_family`}}",
            "image_name": "reddit-base-db-{{timestamp}}",
            "image_family": "reddit-base",
            "ssh_username": "ubuntu",
            "platform_id": "{{user `platform_id`}}",
            "use_ipv4_nat": "true",
            "instance_cores": "{{user `instance_cores`}}",
            "instance_mem_gb": "{{user `instance_mem_gb`}}",
            "instance_name": "{{user `instance_name`}}"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}
```

Финальное содержимое шаблона app.json
```css
{
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "{{user `service_account_key_file_path`}}",
            "folder_id": "{{user `folder_id`}}",
            "source_image_family": "{{user `source_image_family`}}",
            "image_name": "reddit-base-app-{{timestamp}}",
            "image_family": "reddit-base",
            "ssh_username": "ubuntu",
            "platform_id": "{{user `platform_id`}}",
            "use_ipv4_nat": "true",
            "instance_cores": "{{user `instance_cores`}}",
            "instance_mem_gb": "{{user `instance_mem_gb`}}",
            "instance_name": "{{user `instance_name`}}"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}
```

Запускаем сборку новых образов для APP и DB
```css
$ packer build -var-file=variables.json app.json
$ packer build -var-file=variables.json db.json
```

9. Вводим новую переменную для образа APP и DB

В **variables.tf** добавляем
```css
variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app-base"
}
variable db_disk_image {
  description = "Disk image for reddit db"
  default     = "reddit-db-base"
}
```

Получаем id новых образов собранных через packer
```css
$ yc compute image list
```

В **terraform.tfvars** добавляем полученные id образов
```css
app_disk_image           = "***"
db_disk_image            = "***"
```

10. Разделем конфиг **main.tf** на несколько частей

Создадим файл **app.tf** с конфигурацией VM для приложения
```css
$ touch app.tf
```

Содержимое файла **app.tf**
```css
resource "yandex_compute_instance" "app" {
  name = "reddit-app"

  labels = {
    tags = "reddit-app"
  }
  resources {
    cores  = 1
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.app_disk_image
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat = true
  }

  metadata = {
  ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}
```

Создадим файл **db.tf** с конфигурацией VM для приложения
```css
$ touch db.tf
```

Содержимое файла **db.tf**
```css
resource "yandex_compute_instance" "db" {
  name = "reddit-db"
  labels = {
    tags = "reddit-db"
  }

  resources {
    cores  = 1
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.db_disk_image
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat = true
  }

  metadata = {
  ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}
```

11. Создаем файл **vpc.tf**, в который выносим конфигурацию сети и подсети

```css
touch vpc.tf
```

Содержимое файла **vpc.tf**
```css
resource "yandex_vpc_network" "app-network" {
  name = "app-network"
}

resource "yandex_vpc_subnet" "app-subnet" {
  name           = "app-subnet"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.app-network.id}"
  v4_cidr_blocks = ["192.168.10.0/24"]
}
```

12. После выноса конфигураций по разнам файлам в **main.tf** остается только определение провайдера
```css
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}
```

13. В outputs.tf добавляем вывод адресов инстансов
```css
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
output "external_ip_address_db" {
  value = yandex_compute_instance.db.network_interface.0.nat_ip_address
}
```

14. Применяем конфигурацию, проверяем ошибки, при необходимости устраняем
```css
$ terraform apply
``` 

15. После успешного деплоя, заходим на каждый хост по ssh и проверяем факт установки необходимого ПО
    После проверки удаляем инстансы
```css
$ terraform destroy
```

## Подготовка конфигурационных файлов для работы с модулями

16. Создаем структуру каталогов для DB
```css
$ mkdir -p modules/db
```

17. Копируем конфигурацию для DB в модули
```css
$ cp db.tf modules/db/main.tf
``` 

18. В файле **modules/db/variables.tf** определим переменные, которые используются в db.tf
```css
variable public_key_path {
  description = "Path to the public key used for ssh access"
}
  variable db_disk_image {
  description = "Disk image for reddit db"
  default = "reddit-db-base"
}
variable subnet_id {
description = "Subnets for modules"
}
```

19. Создаем структуру каталогов для APP
```css
$ mkdir -p modules/app
```

20. Копируем конфигурацию для APP в модули
```css
$ cp app.tf modules/app/main.tf
``` 

21. В файле **modules/app/variables.tf** определим переменные, которые используются в app.tf
```css
variable public_key_path {
  description = "Path to the public key used for ssh access"
}
variable app_disk_image {
  description = "Disk image for reddit app"
  default = "reddit-app-base"
}
variable subnet_id {
description = "Subnets for modules"
}
```

22. Вывод выходных переменных в файлы

Файл **modules/app/outputs.tf**
```css
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
```

Файл **modules/db/outputs.tf**
```css
output "external_ip_address_db" {
  value = yandex_compute_instance.db.network_interface.0.nat_ip_address
}
```

23. Удаление ненужных файлов в основном каталоге terraform
```css
$ rm db.tf и app.tf vpc.tf
```

24. После удаления **vpc.tf** в файлах **modules/db/main.tf** и **modules/app/main.tf** скорректировал значение subnet_id

Было
```css
  network_interface {
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat = true
  }
```

Стало
```css
  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }
```

25. В главный конфигурационный файл **main.tf** добавляем вызов модулей
```css
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}
module "app" {
  source          = "./modules/app"
  public_key_path = var.public_key_path
  app_disk_image  = var.app_disk_image
  subnet_id       = var.subnet_id
}

module "db" {
  source          = "./modules/db"
  public_key_path = var.public_key_path
  db_disk_image   = var.db_disk_image
  subnet_id       = var.subnet_id
}
```

26. В каталоге terraform выхываем загрузку модулей
```css
$ terraform get
```

27. Переопределяем переменную для внешнего ip в файле **outputs.tf**
```css
output "external_ip_address_app" {
  value = module.app.external_ip_address_app
}
output "external_ip_address_db" {
  value = module.db.external_ip_address_db
}
```

28. Проверим и запустим сборку новых инстансов
```css
$ terraform apply
```

29. Проверяем ssh доступ до инстансов

## Создание Stage и Prod окрудений

30. В каталоге terraform создаем подкаталоги stage и prod
```css
$ mkdir terrform/stage
$ mkdir terrform/prod
```

31. Копируем файлы конфигураций в созданные каталоги
```css
$ cp main.tf variables.tf outputs.tf terraform.tfvars stage
$ cp main.tf variables.tf outputs.tf terraform.tfvars prod
```

32. Изменяем путь до модулей в **main.tf** каталога **stage** и **prod**
```css
source          = "../modules/app"
```

33. Проверка правильности настроек каждого окружения и последующим удаление созданных инстансов


## Самостоятельное задание

1. Удалить из каталога terraform файлы **main.tf**, **outputs.tf**, **terraform.tfvars**, **variables.tf**
```css
$ rm main.tf outputs.tf terraform.tfvars variables.tf
```

2. Форматирование конфигурации файлов в каталогах **stage** и **prod**
```css
$ terarform fmt
```

## Задания с ⭐
Настройка хранения стейт файла в remote backends

1. Копируем в основной каталог terraform файлы **main.tf**, **variables.tf** и **terraform.tfvars** для создания bucket
```css
$ cp stage/main.tf main.tf
$ cp stage/variables.tf variables.tf 
$ cp stage/terraform.tfvars terraform.tfvars
```

2. Описываем  переменные необходимые для создания bucket

В файл **variables.tf** добавляем строки
```css
variable access_key {
  description = "Static access key identifier"
}
variable secret_key {
  description = "Secret access key value"
}
variable bucket {
  description = "Bucket name"
}
```

Выполняем команду для получения значений access_key, secret_key
```css
$ yc iam access-key create --service-account-name terraform
```

Полученные значения и имя создаваемого бакета записываем в файл **terraform.tfvars**
```css
access_key               = "***"
secret_key               = "***"
bucket                   = "dberezikov-bucket"
```

3. Корректируем файл **main.tf** описывая в нем конфигурацию создаваемого бакета
```css
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}
resource "yandex_storage_bucket" "dberezikov-otus-bucket" {
  access_key    = var.access_key
  secret_key    = var.secret_key
  bucket        = var.bucket
#  force_destroy = true
}
```

4. Проверяем корректность конфигурации и создаем бакет
```css
$ terraform plan
$ terraform apply
```

5. В каждой директории **stage** и **prod** создаем файл **backend.tf**

Конфигурационный файл не поддерживает переменные, пришлось указать значения параметров в явном виде

Содержимое файла
```css
terraform {
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "dberezikov-bucket"
    key        = "stage/terraform.tfstate"   ## значение "prod/terraform.tfstate" для каталога prod
    region     = "ru-central1"
    access_key = "***"
    secret_key = "***"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
```

6. После сохранения файла необходимо выполнить команду в каталогах **stage** и **prod**
```css
$ terraform init
```

7. При одновременном запуске деплоя инстансов из сред stage и prod возникает ошибка, т.к. название инстансов не уникальны для каждой среды, введем переменные

Добавляем в **module/app/variables.tf**
```css
variable app_instance_name {
  description = "Name of APP instance"
  default     = "reddit-app"
}
```
Добавляем в **module/db/variables.tf**
```css
variable db_instance_name {
  description = "Name of DB instance"
  default     = "reddit-db"
}
```

В **modules/app/main.tf** корректируем имя инстанса
```css
resource "yandex_compute_instance" "app" {
  name = var.app_instance_name
  labels = {
    tags = var.app_instance_name
  }
```

В **modules/db/main.tf** корректируем имя инстанса
```css
resource "yandex_compute_instance" "db" {
  name = var.db_instance_name
  labels = {
    tags = var.db_instance_name
  }
```

В файл **variables.tf** каждой среды добавляем
```css
variable app_instance_name {
  description = "Name of APP instance"
}
variable db_instance_name {
  description = "Name of DB instance"
}
```

В **terraform.tfvars** каждой среды добавляем
```css
app_instance_name        = "reddir-app-prod" # "reddir-app-stage" для stage среды 
db_instance_name         = "reddir-db-prod"  # "reddir-db-stage"  для stage среды
```

В **main.tf** в модули добавляем строки с переменными для имен инстансов
```css
module "app" {
...
 app_instance_name = var.app_instance_name
}
module "db" {
...
 db_instance_name  = var.db_instance_name
}
```

8. Удаляем файлы **terraform.tfstate** в каждой среде

9. Запукаем проверку на ошибки и сборку инстансов
```css
$ terraform apply
```

10. Проверяем созданные инстансы

## Задания с ⭐

До конца реализовать задание неудалось.
Были добавленые провиженеры в модули, сборка и установка проходит, но не разобрался как реализовать подключение от приложения к БД по внутреннему ip. Пока, что бы не тормозить выполнение других ДЗ, задачу осталяю, позже вернусь, что бы доделать.

# ДЗ №8 "Управление конфигурацией. Основные DevOps инструменты. Знакомство с Ansible"

1. Создаем новую ветку в репозитории
```css
$ git checkout -b ansible-1
```

2. Установка Python и pip
   На сервер уже был установлен python3, проверим его версию
```css
$ python3 --version
```

Установим пакетный менеджер pip
```css
$ sudo apt install python3-pip
```

3. Установим Ansible и проверим версию
```css
$ pip3 install ansible
$ ansible --version
```

4. Задеплоим через terraform **app** и **db** сервер из прошлого урока окружения **stage**
```css
$ cd stage
$ terraform apply -auto-approve
```

5. Создадим **inventory** файл с указанием информации для подключения к созданным хостам
```css
$ mkdir ansible
# cd ansible
$ touch inventory
```

Содержимое файла **inventory**
```css
appserver ansible_host=<ip app сервера>
dbserver ansible_host=<ip db сервера>
```

6. Создадим файл **ansible.cfg** с параметрами для подключения к хостам
```css
$ touch ansible.cfg
```

Содержимое файла

```css
[defaults]
inventory = ./inventory
remote_user = ubuntu
private_key_file = ~/.ssh/appuser
host_key_checking = False
retry_files_enabled = False

```

7. Проверим команду ping до каждого из серверов
```css
$ ansible appserver -m ping
$ ansible dbserver -m pingi
```
В командах не указывается путь до **inventory** файла, т.к. этот путь мы указали в **ansible.cfg**

8. Скорректируем файл **inventory** и разделим хосты на группы
```css
[app]
appserver ansible_host=<ip app сервера>

[db]
dbserver ansible_host=<ip db сервера>
```

9. Проверяем команду ping для всей группы хостов app
```css
$ ansible app -m ping
```

10. Создаем файл **inventory.yml** и переносим в него содержимое файла **inventory**
```css
$ touch inventory.yml
```

Содержимое файла
```css
app:
  hosts:
    appserver:
      ansible_host: <ip app сервера>
db:
  hosts:
    dbserver:
      ansible_host: <ip db сервера>
```

11. Переопределим путь до **inventory** файла в **ansible.cfg**
```css
[defaults]
inventory = ./inventory.yml
remote_user = ubuntu
private_key_file = ~/.ssh/appuser
host_key_checking = False
retry_files_enabled = False
```

12. Проверим выполнение команд

Проверка факта установки ruby и bundler на app сервере через модуль **command** (работает только для одной команды)
```css
$ ansible app -m command -a 'ruby -v'
$ ansible app -m command -a 'bundler -v'
```

Проверка через модуль **shell** для нескольких комманд
```css
$ ansible app -m shell -a 'ruby -v; bundler -v'
```

13. Проверим для db сервера статус mongodb через модули **command** и **systemd**
```css
$ ansible db -m command -a 'systemctl status mongod'
$ ansible db -m systemd -a name=mongod
```

14. Более универсальным является модуль **service**, т.к. возвращает ряд переменных
```css
$ ansible db -m service -a name=mongod
```

15. Применение модуля **command** и **git** для клонирования репозиториев

Модуль **command**
```css
$ ansible app -m command -a \
 'git clone https://github.com/express42/reddit.git /home/ubuntu/reddit'
```

Модуль **git**
```css
$ ansible app -m git -a \
 'repo=https://github.com/express42/reddit.git dest=/home/ubuntu/reddit'
```

16. Написание playbook для клонирования репозитория
```css
$ touch clone.yml
```

Содердимое файла **clone.yml**
```css
---
- name: Clone
  hosts: app
  tasks:
    - name: Clone repo
      git:
        repo: https://github.com/express42/reddit.git
        dest: /home/ubuntu/reddit
```

Проверка выполнения playbook
```css
$ ansible-playbook clone.yml
```
В результатх вывода видно, что изменений не было **changed=0**, т.к. репозиторий уже был клонирован ранее через другие модули, перед выполнением проводится проверка на наличие файлов
```css
PLAY RECAP *************************************************************************************************************************************************************************************************************************************************  
appserver                  : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

17. Удаление с app сервера ранее клонированного через другие модули репозитория и повторынй запуск playbook
```css
$ ansible app -m shell -a 'rm -rf ~/reddit'
```

Повторный запуск playbook
```css
$ ansible-playbook clone.yml
```

Теперь в выводе есть измениния, о чем свидетельствует счетчик *changed=1*
```css
PLAY RECAP *************************************************************************************************************************************************************************************************************************************************  
appserver                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

## Задания с ⭐
## Динамическое инвентори

По условию задания необходимо:
1. Создать файл **inventory.json** в формате описанном в [документации](https://nklya.medium.com/%D0%B4%D0%B8%D0%BD%D0%B0%D0%BC%D0%B8%D1%87%D0%B5%D1%81%D0%BA%D0%BE%D0%B5-%D0%B8%D0%BD%D0%B2%D0%B5%D0%BD%D1%82%D0%BE%D1%80%D0%B8-%D0%B2-ansible-9ee880d540d6)
2. Написать скрипт позволяющий генерировать **inventory.json** на лету из реальных данных о хостах взятых в Yandex.Cloud
3. В файле **ansible.cfg** сделать настройки для работы с JSON-inventory
4. Готовые утилиты не рассматриваем, пишем свою реализацию

### Реализация

1. Что бы получить список хостов из Yandex.Cloud используем консольную утилиту **yc compute instance list** с форматированием вывода
```css
yc compute instance list | awk '{print$10}' | grep -v '^|' | sed -E '/^$/d'
```

Результат вывода
```css
62.84.124.197
62.84.126.118
```

2. Теперь имея вывод ip адресов хостов можем записать его в временный inventory файл **inventory_temp** с простой структурой
```css
[all]
62.84.124.197
62.84.126.118
```

Имея только экспорт списка хостов через консольную утилиту, мы заранее не знаем к каким группам относятся хосты, поэтому объеденим хосты в группу [all]

3. Теперь можно вызвать команду **ansible-inventory** и в качестве входящего параметра указать созданный временный inventory файло, что бы сформировать json файл формата по требования п1 условия задания
   Результат выполнения команды **ansible-inventory --list -i inventory_temp**:
```css
{
    "_meta": {
        "hostvars": {}
    },
    "all": {
        "children": [
            "ungrouped"
        ]
    },
    "ungrouped": {
        "hosts": [
            "62.84.124.197",
            "62.84.126.118"
        ]
    }
}
```

4. Оформляем скрипт по условиям [документации](https://nklya.medium.com/%D0%B4%D0%B8%D0%BD%D0%B0%D0%BC%D0%B8%D1%87%D0%B5%D1%81%D0%BA%D0%BE%D0%B5-%D0%B8%D0%BD%D0%B2%D0%B5%D0%BD%D1%82%D0%BE%D1%80%D0%B8-%D0%B2-ansible-9ee880d540d6)

```css
$ touch dinamic-inventory.sh 
```

Как работает скрипт
- При запуске скрипта с параметром **--list** возвращается список хостов в формате JSON и создается файл **inventory.json** с содержимым по условиям п1 задания
- При запуске скрипта с параметром **--host** возвращается **_meta** с пустой секцией **hostvars** т.к. мы не хотим передавать переменные для Ansible для каждого хоста (при текущей реализации у нас нет переменных)

Содержимое скрипта
```css
#!/bin/bash

if [ "$1" == "--list" ] ; then
  if [ -e $inventory_temp ]; then
          echo "[all]" > inventory_temp
  else
          touch inventory_temp
          echo "[all]" > inventory_temp
  fi
  yc compute instance list | awk '{print$10}' | grep -v '^|' | sed -E '/^$/d' >> inventory_temp
  if [ -e $inventory.json ]; then
          ansible-inventory --list -i inventory_temp > inventory.json
  else
          touch inventory.json
          ansible-inventory --list -i inventory_temp > inventory.json
  fi
  ansible-inventory --list -i inventory_temp
  rm inventory_temp
elif [ "$1" == "--host" ]; then
          echo '{"_meta": {"hostvars": {}}}'
  else
          echo "{ }"
fi
```

5. Делаем скрипт исполняемым
```css
$ sudo chmod a+x dinamic-inventory.sh
```

6. Редактируем **ansible.cfg** для работы с JSON-inventory
```css
[defaults]
inventory = ./dinamic-inventory.sh
remote_user = ubuntu
private_key_file = ~/.ssh/appuser
host_key_checking = False
retry_files_enabled = False
```

В качестве inventory указываем сам скрипт **dinamic-inventory.sh**

7. Проверяем работу динамического инвентори на примере модуля ping по п3 описания задачи
```css
ansible all -m ping
```

Пример вывода
```css
62.84.124.197 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
62.84.126.118 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Для дополнительной проверки выключаем хост с ip 62.84.124.197 через web интерфейс или через консоль и повторно запускаем модуль **ping**
```css
62.84.126.118 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Прошла проверка только второго хоста, т.к. первый выключен и его внешний ip не передается в выводе команды ```yc compute instance list```


###  Отличие динамическое инвентори от статического
В статическом инвентори необходимо держать в актуальном состоянии inventory файл и дописывать туда новые хосты, удалять хосты выведенные из работы
В динамическом инвентори скрипт или инвентори плагин позволяет динамически забирать актуальный список хостов из источника

# ДЗ №9 Деплой и управление конфигурацией с Ansible

1. Создаем новую ветку ```ansible-2```
```css
$ git checkout -b ansible-2
```

2. Перед началом работ добавим в ```.gitignore``` временные файлы Ansible
```css
$ echo "*.retry" >> .gitignore
``

3. Создаем playbok 
```css
$ cd ansible
$ touch ansible/reddit_app.yml
```

4. Заполняем playbook ```reddit_app.yml``` сценариями

### Подготовительный этап

4.1 Создаем директорию ```templates``` в корне директории ```ansible```
```css
$ mkdir templates
```

В директории ```templates``` создаем файл шаблона ```mongod.conf.j2```
```css
$ touch templates/mongod.conf.j2
```

Заполняем шаблон содержимым
```css
# Where and how to store data.
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# network interfaces
net:
  port: {{ mongo_port | default('27017') }}
  bindIp: {{ mongo_bind_ip }}
```

Переменная ```mongo_bind_ip``` должна быть задана в разделе ```vars:``` в playbook

4.2 Создаем шаблон ```db_config.j2``` в директории ```templates```
```css
$ touch templates/db_config.j2
```

Содержание ```templates/db_config.j2```
```css
DATABASE_URL={{ db_host }}
```

Переменная ```db_host``` тоже должна быть задана в ```vars:``` в playbook



После добавления сценария для MongoDB, Unit для приложения, настройки инстанса приложения, сценариев деплоя и установки зависимостей playbook должен выглядить следкющим образом

```css
---
- name: Configure hosts & deploy application
  hosts: all
  vars:
    mongo_bind_ip: 0.0.0.0
    db_host: 10.128.0.28
  tasks:
    - name: Change mongo config file
      become: true
      template:
        src: templates/mongod.conf.j2
        dest: /etc/mongod.conf
        mode: 0644
      tags: db-tag
      notify: restart mongod

    - name: Add unit file for Puma
      become: true
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      tags: app-tag
      notify: reload puma

    - name: Add config for DB connections
      template:
        src: templates/db_config.j2
        dest: /home/ubuntu/db_config
      tags: app-tag

    - name: enable puma
      become: true
      systemd: name=puma enabled=yes
      tags: app-tag

    - name: Fetch the latest version of application code
      git:
        repo: 'https://github.com/express42/reddit.git'
        dest: /home/ubuntu/reddit
        version: monolith
      tags: deploy-tag
      notify: reload puma

    - name: Bundle install
      bundler:
        state: present
        chdir: /home/ubuntu/reddit
      tags: deploy-tag

  handlers:
  - name: restart mongod
    become: true
    service: name=mongod state=restarted

  - name: reload puma
    become: true
    systemd: name=puma state=restarted
```

Переменную ```db_host``` необходимо менять при каждом новом создании инстансов

5. В сценарии добавлены теги ```db-tag```, ```app-tag``` и ```deploy-tag``` для возможности вызова отдельных сценариев для хостов типа db и app из одного общего плейбука
   Пример команды вызова сценариев с тегом ```app-tag``` для app сервера
```css
$ ansible-playbook reddit_app.yml --limit app --tags app-tag
``` 

6. Проверка и запуск всех сценариев в playbook
```css
$ ansible-playbook reddit_app.yml --check
$ ansible-playbook reddit_app.yml
```

7. Для проверки результата вызовим в браузере public ip app сервера с портом 9292

8. Делим playbook на сценарии

8.1 Создаем новый файл ```reddit_app2.yml``` в директории ```ansible```
```css
$ touch reddit_app2.yml
```

8.3 Переносим все наработик из reddit_app.yml в новый playbook
Для каждого сценария определяем host и прописываем свой handlers

Содержимое получившегося playbook
```css
---
- name: Configure MongoDB
  hosts: db
  tags: db-tag
  become: true
  vars:
    mongo_bind_ip: 0.0.0.0
  tasks:
    - name: Change mongo config file
      template:
        src: templates/mongod.conf.j2
        dest: /etc/mongod.conf
        mode: 0644
      notify: restart mongod

  handlers:
  - name: restart mongod
    service: name=mongod state=restarted

- name: Configure hosts
  hosts: app
  tags: app-tag
  become: true
  vars:
   db_host: 10.128.0.27
  tasks:
    - name: Add unit file for Puma
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      notify: reload puma

    - name: Add config for DB connections
      template:
        src: templates/db_config.j2
        dest: /home/ubuntu/db_config
        owner: ubuntu
        group: ubuntu

    - name: enable puma
      systemd: name=puma enabled=yes

  handlers:
  - name: reload puma
    systemd: name=puma state=reloaded

- name: Deploy application
  hosts: app
  tags: deploy-tag
  tasks:
    - name: Fetch the latest version of application code
      git:
        repo: 'https://github.com/express42/reddit.git'
        dest: /home/ubuntu/reddit
        version: monolith
      tags: deploy-tag
      notify: restart puma

    - name: Bundle install
      bundler:
        state: present
        chdir: /home/ubuntu/reddit
      tags: deploy-tag

  handlers:
  - name: restart puma
    become: true
    systemd: name=puma state=restarted
```

8.4 Пересоздаем инфраструктуру и проверяем новый playbook
```css
$ terraform destroy
$ terraform apply
$ ansible-playbook reddit_app2.yml
```

Применив ```--tags``` с указание на конкретный тег мы можем вызвать отдельные сценарии playbook


9. Для более удобного использования playbook разобъем его на нескольок отдельных playbooks и перенесем в них необходимые сценарии
   Переименуем прежние playbooks
```css
$ mv reddit_app.yml reddit_app_one_play.yml
$ mv reddit_app2.yml reddit_app_multiple_plays.yml
```

Создадим новые playbooks

```css
$ touch app.yml db.yml deploy.yml
```

Содердимое ```app.yml```
```css
---
- name: Configure hosts
  hosts: app
  become: true
  vars:
   db_host: 10.128.0.25
  tasks:
    - name: Add unit file for Puma
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      notify: reload puma

    - name: Add config for DB connections
      template:
        src: templates/db_config.j2
        dest: /home/ubuntu/db_config
        owner: ubuntu
        group: ubuntu

    - name: enable puma
      systemd: name=puma enabled=yes

  handlers:
  - name: reload puma
    systemd: name=puma state=reloaded
```


Содержимое ```db.yml```
```css
---
- name: Configure MongoDB
  hosts: db
  become: true
  vars:
    mongo_bind_ip: 0.0.0.0
  tasks:
    - name: Change mongo config file
      template:
        src: templates/mongod.conf.j2
        dest: /etc/mongod.conf
        mode: 0644
      notify: restart mongod

  handlers:
  - name: restart mongod
    service: name=mongod state=restarted
```

Содержимое ```deploy.yml```
```css
---
- name: Deploy application
  hosts: app
  tasks:
    - name: Fetch the latest version of application code
      git:
        repo: 'https://github.com/express42/reddit.git'
        dest: /home/ubuntu/reddit
        version: monolith
      tags: deploy-tag
      notify: restart puma

    - name: Bundle install
      bundler:
        state: present
        chdir: /home/ubuntu/reddit
      tags: deploy-tag

  handlers:
  - name: restart puma
    become: true
    systemd: name=puma state=restarted
```

10. Создаем главный playbook, который будет включать в себя все остальные
```css
$ touch site.yml
```

Содержимое файла
```css
---
- import_playbook: db.yml
- import_playbook: app.yml
- import_playbook: deploy.yml
```

11. Для проверки пересоздаем инфратсруктуру и запустим главный playbook
```css
$ terraform destroy
$ terraform apply
$ ansible-playbook site.yml
```

## Задания с ⭐
## Изменим провижининг в Packer

Заменим выполнение bash скриптов в Packer на запуск Ansible сценариев
Условия: Использовать модули ```command``` и ```shell``` нежелательно!

1. Создадим ```ansible/packer_app.yml``` в котором установим Ruby и Bundler
```css
$ touch packer_app.yml
``` 

Содержимое файла
```css
---
- name: Install Ruby and Bundler
  hosts: all
  become: true
  tasks:
    - name: Install packages
      apt:
        update_cache: yes
        name:
        - ruby-full
        - ruby-bundler
        - build-essential
        - git
        state: present
```

2. Создадим ```ansible/packer_db.yml``` в котором установим MongoDB
```css
$ touch packer_db.yml
```

Содердимое файла
```css
---
- name: Install MondoDB
  hosts: all
  become: true
  tasks:
    - name: Add apt key
      apt_key:
        id: 0C49F3730359A14518585931BC711F9BA15703C6
        keyserver: keyserver.ubuntu.com

    - name: Fetch the mongodb repo
      apt_repository:
        repo: deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse
        state: present

    - name: Install MongoDB
      apt:
        name: mongodb-org
        state: present

    - name: Unabled service
      systemd:
        name: mongod
        enabled: yes
```

3. Теперь опишем вызов Ansible сценариев в Packer
   Замена секции Provision в образе packer/app.json
```css
"provisioners": [
    {
         "type": "ansible",
         "playbook_file": "ansible/packer_app.yml"
    }
]
```

Замена секции Provision в образе packer/db.json
```css
"provisioners": [
    {
         "type": "ansible",
         "playbook_file": "ansible/packer_db.yml"
    }
]
```

4. Запускаем билд новых образов через Packer из корня проекта
```css
$ packer build -var-file=packer/variables.json packer/app.json
$ packer build -var-file=packer/variables.json packer/db.json 
```

5. Собирем из полученных образов инстансы через Terraform и проверяем результат

## Задания с ⭐
## Динамический inventory

Удалось в теории разобраться как работает (по внутренней документации) и как запустить [динамический inventory](https://github.com/ansible/ansible/pull/61722), но проверить на практиче и потом все описать пока не хватает времени.

# ДЗ №10 Ansible: работа с ролями и окружениями

1. Создаем ветку ```ansible-3```
```css
$ git checkout -b ansible-3
```

2. В директории ```ansible``` создаем директорию ```roles``` и выполняем в ней команды для создания заготовки ролей
```css
$ mkdir roles
$ cd roles
$ ansible-galaxy init app
$ ansible-galaxy init db
```
Роль для базы данных
3. Копируем секцию ```tasks``` из плейбука ```ansible/db.yml``` и вставим ее в файл в директории ```tasks``` роли ```db```
   Содержимое файла ```ansible/roles/db/tasks/main.yml```
```css
# tasks file for db
- name: Change mongo config file
  template:
    src: templates/mongod.conf.j2
    dest: /etc/mongod.conf
    mode: 0644
  notify: restart mongod
```

4. Копируем конфиг из ```ansible/templates``` в ```ansble/roles/db/templates```
```css
$ cp templates/mongod.conf.j2 roles/db/templates/mongod.conf.j2
```

5. В файле ```roles/db/tasks/main.yml``` оставляем только имя конифга в ```src:```

6. В ```roles/db/handlers/main.yml``` определяем handler
```css
# handlers file for db
- name: restart mongod
  service: name=mongod state=restarted
```

7. В секции переменных по умолчанию ```roles/db/defaults/main.yml``` определим определим переменные
```css
# defaults file for db
mongo_port: 27017
mongo_bind_ip: 127.0.0.1
```

Роль для приложения
8. Копируем секцию ```tasks``` из плейбука ```ansible/app.yml``` и вставим ее в файл в директории ```tasks``` роли ```app```, оставляя тольок имена файлов в ```src``` модулей ```copy``` и ```template```
```css
---
# tasks file for app
- name: Add unit file for Puma
  copy:
    src: puma.service
    dest: /etc/systemd/system/puma.service
  notify: reload puma

- name: Add config for DB connections
  template:
    src: db_config.j2
    dest: /home/ubuntu/db_config
    owner: ubuntu
    group: ubuntu

- name: enable puma
  systemd: name=puma enabled=yes
```

9. Скопируйте файл ```db_config.j2``` из директории ```ansible/templates``` в директорию ```ansible/roles/app/templates/```
```css
$ cp templates/db_config.j2 roles/app/files/db_config.j2
```

10. Файл ```ansible/files/puma.service``` скопируем в ```ansible/roles/app/files/```
```css
$ cp files/puma.service roles/app/files/puma.service
```

11. Описываем handler в ```roles/app/handlers/main.yml```
```css
# handlers file for app
- name: reload puma
  systemd: name=puma state=restarted
```

12. Определяем переменную по умолчанию в ```roles/app/defaults/main.yml```
```css
# defaults file for app
db_host: 127.0.0.1
```

13. В плейбуке ```ansible/app.yml``` удаляем все лишнее и заменяем на вызов роли
```css
- name: Configure App
  hosts: app
  become: true

  vars:
    db_host: 10.132.0.2

  roles:
    - app
```

14. В ```ansible/db.yml``` так удаляем ненужное и прописываем вызов роли
```css
- name: Configure MongoDB
  hosts: db

  become: true

  vars:
    mongo_bind_ip: 0.0.0.0

  roles:
    - db
```

15. Для проверки ролей пересоздаем инфраструктуру и запускаем плейбук
```css
$ terraform destroy
$ terraform apply
$ ansible-playbook site.yml --check
$ ansible-playbook site.yml
```

16. Проверяем доступность приложени через браузер

Разбиваем инфраструктуру на окружения
17. Создадим директории ```environments/stage``` и ```environments/prod```
```css
$ mkdir environments/stage
$ mkdir environments/prod
```

18. Скопируем inventory файл в каждое окружение
```css
$ cp inventory.yml environtents/prod
$ cp inventory.yml environtents/stage
$ rm inventory.yml 
```

19. Определим окружение по умолчанию в ```ansible/ansible.cfg```
```css
[defaults]
inventory = ./environments/stage/inventory # Inventory по-умолчанию задается здесь
remote_user = appuser
private_key_file = ~/.ssh/appuser
host_key_checking = False
``` 
Переменные групп хостов
20. Создадим директорию ```group_vars``` в директориях окружений ```environments/prod``` и ```environments/stage```
```css
$ mkdir environments/stage/group_vars
```
21. Создаем файл environments/stage/group_vars/app для определения переменных для групп хостов app
```css
$ touch environments/stage/group_vars/app 
```

Переносим в него переменные из плейбуков app.yml

22. Создаем файл environments/stage/group_vars/db для определения переменных для групп хостов db
```css
$ touch environments/stage/group_vars/db 
```

23. Создаем файл ```ansible/environments/stage/group_vars/all``` с переменными для группы хостов
    Содержимое файла
```css
env: stage
```

24. Создаем окружение prod и копируем в него конфиги app, db, all из окружения stage изменив в ```ansible/environments/prod/group_vars/all``` значение переменной ```env: prod```

25. Для вывода в терминал информации об окружении делаем под настройки
    Для роли app в файле ansible/roles/app/defaults/main.yml
```css
# defaults file for app
db_host: 127.0.0.1
env: local
```

Для роли db в файле ansible/roles/db/defaults/main.yml:
```css
# defaults file for db
mongo_port: 27017
mongo_bind_ip: 127.0.0.1
env: local
```

Для роли app (файл ansible/roles/app/tasks/main.yml)
```css
# tasks file for app
- name: Show info about the env this host belongs to
debug:
msg: "This host is in {{ env }} environment!!!"
```  

Добавим такой же таск в роль db (файл ansible/roles/db/tasks/main.yml)
```css
# tasks file for db
- name: Show info about the env this host belongs to
debug: msg="This host is in {{ env }} environment!!!"
```

26. Создаем директорию ```ansible/playbooks``` и переносим в нее все плейбуки

27. Создаем директорию ```ansible/old``` и переносим в нее оставшиеся файлы от прошлых ДЗ не относящиеся к текущей конфигурации

28. После переноса плейбуков меняем в конфигах Packer пути до ```packer_app.yml``` и ```packer_db.yml```

29. Улучшаяем ```ansible.cfg```
    Содержимое файла
```css
[defaults]
inventory = ./environments/stage/inventory.yml
remote_user = ubuntu
private_key_file = ~/.ssh/appuser
# Отключим проверку SSH Host-keys (поскольку они всегда разные для новых инстансов)
host_key_checking = False
# Отключим создание *.retry-файлов (они нечасто нужны, но мешаются под руками)
retry_files_enabled = False
# # Явно укажем расположение ролей (можно задать несколько путей через ; )
roles_path = ./roles

[diff]
# Включим обязательный вывод diff при наличии изменений и вывод 5 строк контекста
always = True
context = 5
```

30. Пересоздаем инфраструктуру и проверяем выполнение плейбуков
```css
$ terraform destroy
$ terraform apply
$ ansible-playbook playbooks/site.yml --check
$ ansible-playbook playbooks/site.yml
```

31. Проверим доступность приложения по ip app сервера и порту 9292 из интернета

32. Тестируем инфраструктуру prod, перед этим удаляем инфраструктуру stage

Поднимаем через Terraform prod среду и запускаем ansible-playbook
```css
$ ansible-playbook -i environments/prod/inventory.yml playbooks/site.yml --check
$ ansible-playbook -i environments/prod/inventory.yml playbooks/site.yml
```

33. Проверим доступность приложения по ip app сервера и порту 9292 из интернета

Работа с Community-ролями
Используем роль jdauphant.nginx и настроим обратное проксирование для нашего приложения с помощью nginx

34. Создадим файлы ```environments/stage/requirements.yml``` и ```environments/prod/requirements.yml``` и добавим в них запись
```css
- src: jdauphant.nginx
version: v2.21.1
```

35. Устанавливаем роль
```css
$ ansible-galaxy install -r environments/stage/requirements.yml
```  

36. Добавляем в .gitignore компюнити роль, что бы она не попала в репозиторий
```css
$ echo 'jdauphant.nginx' >> ../.gitignore
```

37. Добавим настройки проксирования nginx в ```stage/group_vars/app``` и ```prod/group_vars/app```
```css
nginx_sites:
  default:
    - listen 80
    - server_name "reddit"
    - location / {
        proxy_pass http://127.0.0.1:порт_приложения;
      }
```

Самостоятельное задание
1. Порт 80 и так открыт (не запрещен), дополнительных настроек делать не трубуется
2. Добавим вызов роли jdauphant.nginx в плейбук app.yml
```css
- name: Configure App
  hosts: app
  become: true

  roles:
    - app
    - jdauphant.nginx
```
3. Плейбук site.yml успешно применился на окружении stage, приложение теперь доступно по порту 80

Работа с Ansible Vault

1. Создадим файл vault.key с произвольной строкой ключа и разместим файл вне репозитория
```css
$ echo '**TTV8k$tsV!fAOPMa1C3G2l9!0zd6U#TzxL#HlG' > ~/.ansible/vault.key
```

2. В ```ansible.cfg``` добавим опцию ```vault_password_file``` в секцию [defaults] с путем до ключем
```css
[defaults]
...
# Vault password file
vault_password_file = ~/.ansible/vault.key
```

3. Добавляем плейбук для создания пользователей
```css
$ touch ansible/playbooks/users.yml
``` 
Содержимое файла
```css
---
- name: Create users
  hosts: all
  become: true

  vars_files:
    - "{{ inventory_dir }}/credentials.yml"

  tasks:
    - name: create users
      user:
        name: "{{ item.key }}"
        password: "{{ item.value.password|password_hash('sha512', 65534|random(seed=inventory_hostname)|string) }}"
        groups: "{{ item.value.groups | default(omit) }}"
      with_dict: "{{ credentials.users }}"
```

4. Создадим файл с данными пользователей для каждого окружения
```css
$ touch ansible/environments/prod/credentials.yml
```

Содержимое файла
```css
---
credentials:
  users:
    admin:
      password: admin123
      groups: sudo
```

```css
$ touch ansible/environments/stage/credentials.yml
```

Содержимое файла
```css
---
credentials:
  users:
    admin:
      password: qwerty123
      groups: sudo
    qauser:
      password: test123
```

5. Шифруем файлы с данными пользователей используя ключ ```vault.key```
```css
$ ansible-vault encrypt environments/prod/credentials.yml
$ ansible-vault encrypt environments/stage/credentials.yml
```

6. Проверяем, файлы зашифрованы

7. Добавляем вызов плейбука ```users.yml``` в ```site.yml```
   Содерждимое ```site.yml```
```css
---
- import_playbook: db.yml
- import_playbook: app.yml
- import_playbook: deploy.yml
- import_playbook: users.yml
```

8. Поднимаем окружение stage и вызываем в нем главный плейбук
```css
$ ansible-playbook site.yml —check
$ ansible-playbook site.yml
```

9. Для проверки того, что необходимые пользователи создались на инстансах app и db, можно через ansible прочитать файл ```/etc/passwd``` на remote хостах
```css
$ ansible app -m shell -a 'cat /etc/passwd'
$ ansible db -m shell -a 'cat /etc/passwd'
```

