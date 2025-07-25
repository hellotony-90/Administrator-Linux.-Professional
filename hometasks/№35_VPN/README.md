## Схема стенда
![1](screen/OVPN.png)
## Подготовка к работе
### Настроим интерфейсф согласно схеме
```
root@vpn-client:~# nano /etc/netplan/50-cloud-init.yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      dhcp4: no
      addresses: [192.168.50.10/24]
```
```
root@vpn-server:~# cat /etc/netplan/50-cloud-init.yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      dhcp4: no
      addresses: [192.168.50.1/24]
```
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
root@vpn-server:/etc/openvpn/easy-rsa# nano /etc/openvpn/server.conf
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
root@vpn-server:/etc/openvpn/easy-rsa# echo 'net.ipv4.ip_forward=1' | tee -a /etc/sysctl.conf
root@vpn-server:/etc/openvpn/easy-rsa# sysctl -p
```
### Запускаем сервис, добавляем в автозагрузку и смотрим статус
```
root@vpn-server:/etc/openvpn/easy-rsa# systemctl start openvpn@server
root@vpn-server:/etc/openvpn/easy-rsa# systemctl enable openvpn@server
root@vpn-server:/etc/openvpn/easy-rsa# systemctl status openvpn@server
```
## Создаем клиентускую сторону
### Генерируем сертификаты
```
root@vpn-server:/etc/openvpn/easy-rsa# ./easyrsa gen-req client1 nopass
root@vpn-server:/etc/openvpn/easy-rsa# ./easyrsa sign-req client client1
```
### Создаем подключение
```
root@vpn-client:~# nano ~/client1.ovpn
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
MIIDQjCCAiqgAwIBAgIUOzHAF13N3MNPCS5oZQ+4a67KptUwDQYJKoZIhvcNAQEL
BQAwEzERMA8GA1UEAwwIb3R1cy1sYWIwHhcNMjUwNzI0MTMzMjU4WhcNMzUwNzIy
MTMzMjU4WjATMREwDwYDVQQDDAhvdHVzLWxhYjCCASIwDQYJKoZIhvcNAQEBBQAD
ggEPADCCAQoCggEBALXsAx+oDeGomLD42USjfTnz8EkqSIaee7KOMWy34WIjD1Aa
xq3P34rIB2oznUegoKd7u7cruNX7yC4YhlBxkaar91cA7mQG/D4ML5xYdoC8jn51
wWncK3B9Pkt0tnd8QmulKVJJT7dgqWnpVei8/8TrfMow+tCpm0MA6gHb8ACLNh+p
mVN9aw1XD+SuWabmYlufMahlzGZWdAcRxeSSNbRyH41JUXe+5+jtUoBwBz/fRsLw
irpa61EQh4Hb9sQYTk6iZeaXRV7sichntroUqvSu3uzn4KlAILZEMX7YgBDsRSNq
Oiv7OfrQklIER/sBslblyknDk7kcKl3FrWWYezkCAwEAAaOBjTCBijAMBgNVHRME
BTADAQH/MB0GA1UdDgQWBBQ0lpqrSlflfo8mxbxwn6B4G7U7JTBOBgNVHSMERzBF
gBQ0lpqrSlflfo8mxbxwn6B4G7U7JaEXpBUwEzERMA8GA1UEAwwIb3R1cy1sYWKC
FDsxwBddzdzDTwkuaGUPuGuuyqbVMAsGA1UdDwQEAwIBBjANBgkqhkiG9w0BAQsF
AAOCAQEALOUHAIcNPTOZSeD5e2UDdZBpNYThWQTbqhsIhJp7UF79JG26t7klLLtB
S9LekbJafEyaOGcwOzW/Dk6RpDAQ8eakgNH0OvDQu5jvdNqD95S6dwqKPc5Hy9kj
ueg/mgt8M6xBDqtr9GXdLpb9xoEvkqBzDV4GIwstYW49lqr60BJVjEFVmAlATIy3
RB2+dCfeN1MljNzt5C9hGO+wbmkRBDXvRqbkUqdVFIafjbMkjNW2g7mY9DH24joa
Tqd1+7GY2QE90TMDLwrGYdmywdK4CpzNX8gyLLqp8O669rNokscJAIYJ7HfRiHgl
kELG+RXF1Wv2wfgMomOo8bCoow2uGQ==
-----END CERTIFICATE-----
</ca>
<cert>
-----BEGIN CERTIFICATE-----
MIIDUDCCAjigAwIBAgIRAKj9XBT91tvQY5S8Zh20u2wwDQYJKoZIhvcNAQELBQAw
EzERMA8GA1UEAwwIb3R1cy1sYWIwHhcNMjUwNzI0MTM0NzQ1WhcNMjcxMDI3MTM0
NzQ1WjASMRAwDgYDVQQDDAdjbGllbnQxMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
MIIBCgKCAQEAs/tEaZOczHr0sRG2HHt24T9zEgwE8a4K9vMgfVOLo+g5zJZPGDIr
C3jDqS7hxHUGYTLn+O5zrDdb2cbjJSkCUDrYCI/aE9PHKwKiG5983ix9sQiLklG8
jHt8JuzuuolDYqFv5MsodXCPBk8qqd7tuDGyCDbwfTYLW+qt0vAYIl1n0keTwbm1
3dnsx3Tat6KlBsR+WXEF52kePiDvvhlKlzp5u6hR8UVTNNQvfimF3dY5vSNwsN70
IuzYKueuv8RPBM1DcrdFefp0YVdgInEQdolBLSj8JDgzPvlLjtBnR5xwSB684yFe
HWN62BqlwuZW+MWFYKKUX8bxSX7H5CuroQIDAQABo4GfMIGcMAkGA1UdEwQCMAAw
HQYDVR0OBBYEFNIFQ7ad8uPbBcSwpIxZI7XJ0NQ2ME4GA1UdIwRHMEWAFDSWmqtK
V+V+jybFvHCfoHgbtTsloRekFTATMREwDwYDVQQDDAhvdHVzLWxhYoIUOzHAF13N
3MNPCS5oZQ+4a67KptUwEwYDVR0lBAwwCgYIKwYBBQUHAwIwCwYDVR0PBAQDAgeA
MA0GCSqGSIb3DQEBCwUAA4IBAQAL6vjviwtkqYTqyRt6xc9ONFKl2Swt+5Dem3S8
+IIG8kvZfY8+AZrQSIj2cSh85M9QEKTScBB8SXlEicMtaX/puSDTg36I5yrp+F6J
ibO8zi6dGmb1Jb4Gsr8lAu1iYR/bbSpahp7GMqcELmIMH8pXfI3SnL3PGJhkXY3G
LUW6zLp4q2NFh2f6xtD0t+Q9rMaxn8ee/RkjLTsDPLVn4o3ATERferUUdr6AIaav
MFnc3thaar1vAnTp1gxUC5Dk9NhZ/kzvzXCPImIbNeStLHUZW/I6J0xrabSUt8nV
YIArhLespaSfze8PA4ZseermEprk7PzwvXFssaUMFOhyyUXx
-----END CERTIFICATE-----
</cert>
<key>
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCz+0Rpk5zMevSx
EbYce3bhP3MSDATxrgr28yB9U4uj6DnMlk8YMisLeMOpLuHEdQZhMuf47nOsN1vZ
xuMlKQJQOtgIj9oT08crAqIbn3zeLH2xCIuSUbyMe3wm7O66iUNioW/kyyh1cI8G
Tyqp3u24MbIINvB9Ngtb6q3S8BgiXWfSR5PBubXd2ezHdNq3oqUGxH5ZcQXnaR4+
IO++GUqXOnm7qFHxRVM01C9+KYXd1jm9I3Cw3vQi7Ngq566/xE8EzUNyt0V5+nRh
V2AicRB2iUEtKPwkODM++UuO0GdHnHBIHrzjIV4dY3rYGqXC5lb4xYVgopRfxvFJ
fsfkK6uhAgMBAAECggEAE5h3/XwzOk6pSUWVw7JcEkBpn4WEPMl/m11DdG22EouQ
TnJvjGF67wnwGKGYdl6s6gSEPeW9XZrd4t89ACDfxfswJfd+jYHVaZ0E6BfEXT6w
FSgqZQ0F57Ayp1zMza2v8uNDhuApKKcvhUb1jM7vKCqt+Oe9ZY6OrExn7kNSh1wf
iRQ6A49Heuu8iaG7GL8x3hoWeQPLv/eZFlfL4uyYd/cBgF/KEVey2GloiqmvjVXj
M+0VQTkNouVmfm5XAmPiKvjAWbPyS2DxR8it4oebfABdSvfgy2PwRWsVZfjFWH3V
KWPnINtMFCAjSxTxURx8bAU0iB5CcgOkA6DDahZCCQKBgQD6ucmTyZ8UeNqJ/hzA
1ZiO36Oa6QKW/uJr3Xi/zIVpNSUI99xni2P9Me55GrstFbt3ww/OJwIftmNisDuc
P9tT6mziAlnPGmCiDyPQ3AB9AEGRGzzMKMnbBktbkK4XqmxRYbVgTL4VS6bNxCVN
h0NwudhjO9AXTUlhJMTU7XtHuQKBgQC3xIG+6a8mFKDnXQZKwgxusnFWNTggpBF2
/2/46t+phQLxO7mQ+jKS8y2mD8Gg/3vWK0703LOtw2G97A0gtBIqj5GrWlWmcA9n
lg1FsRPBd3XfxCt1A7JqobmpnenK24hGgDrazMo16Pt/BEfG7B3Cz93+4xISAPKf
Iphbb4AnKQKBgQDNKVesKfCVNOtGvXvTwzRpvNBIQ2DOI9UtBHX5JCcK1uTuOLvO
sr3oAoKr8Fa3ZrAXKLN3Mm5HetxKdgDhM1OKkCn2qovIr0HhelgJYOy5XItKbKpM
ORgrtDPXwkTisp6d3UEogsOL83KTr2wCy6tAw6IwWVJGrwRbjFXQEl+taQKBgES0
TSXJTFhaYgXd+5o7jlZclI78eq2JaZYpzf0sIs7IEd+KysfvIrVaAXkSbvv4SJ47
tttJIEwYvhQ5inbtm9UZtAZyUY9WWgwKR5AEsjQkq4crWmv3I99F85n8lgnnpb1l
95sR8Y/SOSS1vvgaEs5g1MiUsI7Wl97zGi8lMq5xAoGAGnBkyMFLO+MPLzd/9QCZ
1DHd0a+oAb9ORcueNfRlFPUu7cnFUpDywjfvGpklEdFD9aaZ7OlEIsxK8lQpM9sD
FEpGCktkT/fqy+mEVpHHsdWxpSV/gAK0DUnm40VgXSDxOnnL92OUDI5+hSL5guSc
VIEZf2bKQIdSVOgNjo2txZI=
-----END PRIVATE KEY-----
</key>
<tls-auth>
-----BEGIN OpenVPN Static key V1-----
d3a02a2dcf388e0463dd4c7de0891eee
596cd09de6b83d0a9948c54ccc13a726
d6429269551e0d02c105f72cc20189d4
7fa2cd2128b836e12a85c6f47a590cf7
f40ea4fda6f2433b4af26b15dfe8d761
ee5c6f48a0b6f743b34757332ddd801c
a08c6b09267a90a7d0cf1d8ff056e5ad
1cc80bd50fc12e3d3698a1cdf4722c09
d990b5462349278f422faa01faccd43e
37482de8434a8435488b14a4ea366b72
763b17e7a129c2160860d6577b1df62e
80cc65b825c12943b2ea33f3040cc8b9
22d4abe3678f9a5694f6d7807be919c7
d0bc37c82e8ed504df609350ae69a254
8058c3c61dd4ab00945b145a251b4b4a
20b3545ceb3db382ff086a5fa9df1f45
-----END OpenVPN Static key V1-----
</tls-auth>
key-direction 1
```
## Проверка работоспособности стенда
### Мы начинаем VPN ☺
```
root@vpn-client:~# openvpn --config /etc/openvpn/client1.ovpn
```
### Проверка связности
```
root@vpn-server:~# ip a
4: tap0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 1000
    link/ether ee:6b:73:47:5f:44 brd ff:ff:ff:ff:ff:ff
    inet 192.168.51.1/24 scope global tap0
       valid_lft forever preferred_lft forever
    inet6 fe80::e489:bdff:fe2c:fc73/64 scope link
       valid_lft forever preferred_lft forever

root@vpn-client:~# ip a
4: tap0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 1000
    link/ether ee:6b:73:47:5f:44 brd ff:ff:ff:ff:ff:ff
    inet 192.168.51.4/24 scope global tap0
       valid_lft forever preferred_lft forever
    inet6 fe80::cc6a:48ff:fe86:2dfe/64 scope link
       valid_lft forever preferred_lft forever
PING 192.168.51.1 (192.168.51.1) 56(84) bytes of data.
64 bytes from 192.168.51.1: icmp_seq=1 ttl=64 time=0.981 ms
64 bytes from 192.168.51.1: icmp_seq=2 ttl=64 time=1.60 ms
64 bytes from 192.168.51.1: icmp_seq=3 ttl=64 time=1.69 ms
64 bytes from 192.168.51.1: icmp_seq=4 ttl=64 time=1.07 ms
64 bytes from 192.168.51.1: icmp_seq=5 ttl=64 time=1.28 ms
64 bytes from 192.168.51.1: icmp_seq=6 ttl=64 time=1.50 ms
^C
--- 192.168.51.1 ping statistics ---
6 packets transmitted, 6 received, 0% packet loss, time 5009ms
rtt min/avg/max/mdev = 0.981/1.352/1.687/0.263 ms
```
### Замер iperf режим tap
```
root@vpn-client:~# iperf3 -c 192.168.51.1
Connecting to host 192.168.51.1, port 5201
[  5] local 192.168.51.4 port 41658 connected to 192.168.51.1 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  82.8 MBytes   694 Mbits/sec   97    189 KBytes
[  5]   1.00-2.00   sec  79.5 MBytes   667 Mbits/sec  106    207 KBytes
[  5]   2.00-3.00   sec  77.8 MBytes   652 Mbits/sec   70    168 KBytes
[  5]   3.00-4.00   sec  79.2 MBytes   665 Mbits/sec   64    211 KBytes
[  5]   4.00-5.00   sec  77.8 MBytes   652 Mbits/sec   63    176 KBytes
[  5]   5.00-6.00   sec  77.1 MBytes   647 Mbits/sec   93    234 KBytes
[  5]   6.00-7.00   sec  79.1 MBytes   664 Mbits/sec   50    105 KBytes
[  5]   7.00-8.00   sec  78.6 MBytes   660 Mbits/sec   26    216 KBytes
[  5]   8.00-9.00   sec  82.8 MBytes   694 Mbits/sec  120    171 KBytes
[  5]   9.00-10.00  sec  78.5 MBytes   658 Mbits/sec   77    127 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec   793 MBytes   665 Mbits/sec  766             sender
[  5]   0.00-10.00  sec   792 MBytes   664 Mbits/sec                  receiver

iperf Done.
```
### Замер iperf режим tun
```
root@vpn-client:~# iperf3 -c 192.168.51.1
Connecting to host 192.168.51.1, port 5201
[  5] local 192.168.51.6 port 39466 connected to 192.168.51.1 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  78.6 MBytes   659 Mbits/sec   50    182 KBytes
[  5]   1.00-2.00   sec  87.2 MBytes   732 Mbits/sec   99    144 KBytes
[  5]   2.00-3.00   sec  86.0 MBytes   721 Mbits/sec   80    131 KBytes
[  5]   3.00-4.00   sec   138 MBytes  1.16 Gbits/sec   74    178 KBytes
[  5]   4.00-5.00   sec  84.5 MBytes   709 Mbits/sec   66    161 KBytes
[  5]   5.00-6.00   sec  78.8 MBytes   661 Mbits/sec   77    186 KBytes
[  5]   6.00-7.00   sec  79.9 MBytes   670 Mbits/sec   70    209 KBytes
[  5]   7.00-8.00   sec  80.2 MBytes   673 Mbits/sec   34    153 KBytes
[  5]   8.00-9.00   sec  80.2 MBytes   673 Mbits/sec   20    188 KBytes
[  5]   9.00-10.00  sec  81.2 MBytes   681 Mbits/sec   31    149 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec   875 MBytes   734 Mbits/sec  601             sender
[  5]   0.00-10.00  sec   874 MBytes   733 Mbits/sec                  receiver

iperf Done.
```
