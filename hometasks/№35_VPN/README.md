## Подготовка к работе
### Обновим список пакетов и уже установленные пакеты
```
root@vpn-server:~# apt update
root@vpn-server:~# apt upgrade -y
```
### Установим Open-VPN и Easy-RSA
```
root@vpn-server:~# apt install -y openvpn easy-rsa
```
## Настраиваем Центр сертификации (CA)
### Создаем каталог для Easy-RSA и переходим в него::
```
root@vpn-server:~# mkdir -p ~/openvpn-ca && cd ~/openvpn-ca
```
### Инициализируем инфраструктуру открытых ключей(PKI):
```
root@vpn-server:~/openvpn-ca# mkdir /etc/openvpn/easy-rsa/
root@vpn-server:~/openvpn-ca# cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/
root@vpn-server:~/openvpn-ca# cd /etc/openvpn/easy-rsa/
root@vpn-server:/etc/openvpn/easy-rsa# ./easyrsa init-pki
Notice
------
'init-pki' complete; you may now create a CA or requests.
```
### Создаем Центр Сертификации (CA):
```
root@vpn-server:/etc/openvpn/easy-rsa#  ./easyrsa build-ca
## Вводим пароль и подтверждаем его, пишем название ##
Enter New CA Key Passphrase:
Confirm New CA Key Passphrase:
Common Name (eg: your user, host, or server name) [Easy-RSA CA]:otus-lab
## После генерации видим ##
Notice
------
CA creation complete. Your new CA certificate is at:
* /etc/openvpn/easy-rsa/pki/ca.crt
```
### Генерируем сертификаты клиента и сервера, при появлении запроса подтверждаем
```
root@vpn-server:/etc/openvpn/easy-rsa# ./easyrsa gen-req server nopass
root@vpn-server:/etc/openvpn/easy-rsa# ./easyrsa sign-req server server
```
### Генерируем файл параметров Диффи-Хеллмана
```
./easyrsa gen-dh
```
### Создаем shared-key (безопасность не бывает лишней ☺)
```openvpn --genkey secret /etc/openvpn/ta.key ```
## Настраиваем сервер
### Копирую необходимые файлы в директорию OVPN
```
cp pki/ca.crt pki/private/server.key pki/issued/server.crt /etc/openvpn/
cp /etc/openvpn/easy-rsa/pki/dh.pem /etc/openvpn/
cp /etc/openvpn/ta.key /etc/openvpn/
```
### Создаем конфигурационный файл
```
nano /etc/openvpn/server.conf
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
auth SHA256
tls-auth ta.key 0
server 192.168.50.0 255.255.255.0
ifconfig-pool-persist ipp.txt
keepalive 10 120
cipher AES-256-GCM
user nobody
group nogroup
persist-key
persist-tun
status openvpn-status.log
log-append /var/log/openvpn.log
verb 3
```
### Включаем IP-forwarding
```
echo 'net.ipv4.ip_forward=1' | tee -a /etc/sysctl.conf
sysctl -p
```
### Запускаем сервис, добавляем в автозагрузку и смотрим статус
```
systemctl start openvpn@server
systemctl enable openvpn@server
systemctl status openvpn@server
```
## Создаем клиентускую сторону
### Генерируем сертификаты
```
cd /etc/openvpn/easy-rsa/
./easyrsa gen-req client1 nopass
./easyrsa sign-req client client1
```
### Создаем подключение
```
nano ~/client1.ovpn
client
dev tun
proto udp
remote 192.168.50.1 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA256
cipher AES-256-GCM
verb 3
<ca>
-----BEGIN CERTIFICATE-----
# Insert the content of /etc/openvpn/ca.crt here
-----END CERTIFICATE-----
</ca>
<cert>
-----BEGIN CERTIFICATE-----
# Insert the content of /etc/openvpn/easy-rsa/pki/issued/client1.crt here
-----END CERTIFICATE-----
</cert>
<key>
-----BEGIN PRIVATE KEY-----
# Insert the content of /etc/openvpn/easy-rsa/pki/private/client1.key here
-----END PRIVATE KEY-----
</key>
<tls-auth>
-----BEGIN OpenVPN Static key V1-----
# Insert the content of /etc/openvpn/ta.key here
-----END OpenVPN Static key V1-----
</tls-auth>
key-direction 1
```
## Проверка работоспособности стенда
### Мы начинаем VPN ☺
```
openvpn --config /path/to/client1.ovpn
```
