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

