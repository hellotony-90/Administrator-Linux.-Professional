
## Обновим списоу пакетов и уже установленные пакеты
```
root@vpn-server:~# apt update
root@vpn-server:~# apt upgrade -y
```
## Установим Open-VPN и Easy-RSA
```
root@vpn-server:~# apt install -y openvpn easy-rsa
```
## Настраиваем Центр сертификации (CA)
## Create a directory for Easy-RSA and navigate to it:
```
root@vpn-server:~# mkdir -p ~/openvpn-ca && cd ~/openvpn-ca

```
## Initialize the Public Key Infrastructure (PKI):
```
root@vpn-server:~/openvpn-ca# mkdir /etc/openvpn/easy-rsa/
root@vpn-server:~/openvpn-ca# cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/
root@vpn-server:~/openvpn-ca# cd /etc/openvpn/easy-rsa/
root@vpn-server:/etc/openvpn/easy-rsa# ./easyrsa init-pki
Notice
------
'init-pki' complete; you may now create a CA or requests.

```
## Build the Certificate Authority (CA):
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

## Генерируем сертификаты клиента и сервера, при появлении запроса подтверждаем
```
root@vpn-server:/etc/openvpn/easy-rsa# ./easyrsa gen-req server nopass
root@vpn-server:/etc/openvpn/easy-rsa# ./easyrsa sign-req server server
```
## Генерируем файл параметров Диффи-Хеллмана
```
./easyrsa gen-dh
```
## Создаем shared-key (безопасность не бывает лишней ☺)
```openvpn --genkey secret /etc/openvpn/ta.key ```
###
