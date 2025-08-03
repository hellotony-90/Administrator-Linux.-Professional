Схема лабораторной работы 
# Установка FreeIPA сервера
## Подготовка ВМ для работы
### Проверяем сетевые интефрейсы
```
[root@localhost ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:62:91:8e brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.21/24 brd 192.168.1.255 scope global dynamic noprefixroute enp0s3
       valid_lft 5731sec preferred_lft 5731sec
```
### Отключаем ipv6 на интерфейсе enp0s3(при первоначальной установке apache выдал ошибку
||
Could not reliably determine the server's fully qualified domain name, using fe80::a00:27ff:fe62:918e%enp0s3
||
```
net.ipv6.conf.all.disable_ipv6 = 1
```
```
systemctl status chronyd.service
[root@localhost ~]# systemctl status chronyd.service
● chronyd.service - NTP client/server
     Loaded: loaded (/usr/lib/systemd/system/chronyd.service; enabled; preset: enabled)
     Active: active (running) since Sun 2025-08-03 12:50:09 MSK; 53min ago
       Docs: man:chronyd(8)
             man:chrony.conf(5)
   Main PID: 37834 (chronyd)
      Tasks: 1 (limit: 50408)
     Memory: 1016.0K
        CPU: 46ms
     CGroup: /system.slice/chronyd.service
             └─37834 /usr/sbin/chronyd -F 2
```
```
hostnamectl set-hostname ipa.otus.lan
[root@localhost ~]# hostname
ipa.otus.lan

```
Выключим Firewall: systemctl stop firewalld
setenforce 0
Поменяем в файле /etc/selinux/config, параметр Selinux на disabled
vi /etc/selinux/config
SELINUX=disabled
  ```
   
   vi /etc/hosts

127.0.0.1   localhost localhost.localdomain 
127.0.1.1 ipa.otus.lan ipa
192.168.57.10 ipa.otus.lan ipa
  ```
yum install -y ipa-server
ipa-server-install
Далее, нам потребуется указать параметры нашего LDAP-сервера
Setup complete

Next steps:
        1. You must make sure these network ports are open:
                TCP Ports:
                  * 80, 443: HTTP/HTTPS
                  * 389, 636: LDAP/LDAPS
                  * 88, 464: kerberos
                  * 53: bind
                UDP Ports:
                  * 88, 464: kerberos
                  * 53: bind
                  * 123: ntp

        2. You can now obtain a kerberos ticket using the command: 'kinit admin'
           This ticket will allow you to use the IPA tools (e.g., ipa user-add)
           and the web user interface.

[root@localhost ~]# kinit admin
[root@localhost ~]# klist
Ticket cache: KCM:0
Default principal: admin@OTUS.LAN

Valid starting       Expires              Service principal
03.08.2025 13:35:52  04.08.2025 13:21:00  krbtgt/OTUS.LAN@OTUS.LAN
[root@localhost ~]# kdestroy
[root@localhost ~]# klist
klist: Credentials cache 'KCM:0' not found


c:\Windows\System32\Drivers\etc\hosts
192.168.1.21 ipa.otus.lan


картинка 2
картинка 3

На этом установка и настройка FreeIPA-сервера завершена.
