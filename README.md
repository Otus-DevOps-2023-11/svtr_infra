# ДЗ Знакомство с облачной инфраструктурой Yandex.Cloud

Исследоватþ способ подклĀчениā к someinternalhost в одну команду из вашего
рабочего устройства, проверитþ работоспособностþ найденного решениā и внести
его в README.md в вашем репозитории

ssh -A -J appuser@51.250.99.91 appuser@10.129.0.15

Дополнителþное задание:
Предложитþ вариант решениā длā подклĀчениā из консоли при помощи командý
вида ssh someinternalhost из локалþной консоли рабочего устройства, чтобý
подклĀчение вýполнāлосþ по алиасу someinternalhost и внести его в README.md в
вашем репозитории

Для подключения через алиас необходим конфигурационный файл в папке ~/.ssh/config
Host bastion HostName 84.201.139.22 User appuser
Host someinternalhost HostName 10.129.0.15 User appuser ProxyJump bastion
Host * IdentityFile ~/.ssh/appuser

Литература https://techviewleo.com/install-pritunl-vpn-on-ubuntu-server/

https://askubuntu.com/questions/1416430/unable-to-locate-package-mongodb-org-in-ubuntu-22-04 в пакете ошибка вида
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc |  gpg --dearmor | sudo tee /usr/share/keyrings/mongodb.gpg > /dev/null
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt update
sudo apt install mongodb-org


mongodb://localhost:27017/pritunl
4c73241f5980459eb04831827027b033
pritunl
vxhfIVao3Zwc
bastion_IP = 51.250.99.91
someinternalhost_IP  = 10.129.0.15

подключились OpenVPN , увидели https://51.250.99.91/#/users что пользователь подключился , находится online
Проверили как указано в задание 
Проверили что успешно подключились Проверþте возможностþ подклĀчениā к someinternalhost с вашего компþĀтера
после подклĀчениā к VPN:
ssh -i ~/.ssh/appuser appuser@<внутренний IP someinternalhost