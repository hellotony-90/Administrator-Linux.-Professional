#Работа с NFS 

Подготовка [сервера] (files/server.txt)
Подготовка [клиента] (files/client.txt)

## 1. Проверка работоспособности 
### Создаём тестовый файл 111.txt
```
touch /srv/share/upload/111.txt
```
### Заходим на клиент и проверяем наличие ранее созданного файла.
```
root@hello:~# ls /mnt/upload/
111.txt
```
### Создаём тестовый файл touch 222.txt 
```
root@hello:~# cd /mnt/upload/
root@hello:/mnt/upload# touch 222.txt
root@hello:/mnt/upload# ls
111.txt  222.txt
root@helloubuntu:/etc# ls /srv/share/upload/
111.txt  222.txt
```
## 2. Предварительно проверяем клиент: 
### Перезагружаем клиент;
```
root@hello:/mnt/upload# reboot now
Broadcast message from root@hello on pts/1 (Fri 2025-04-11 17:21:36 UTC):
The system will reboot now!
```
### Наличие ранее созданных файлов.
```
hello@hello:~$ sudo -i
[sudo] password for hello:
root@hello:~# cd /mnt/upload/
root@hello:/mnt/upload# ls
111.txt  222.txt
root@hello:/mnt/upload#
```
## 3. Проверяем со стороны сервера: 
### Делаем рестарт
```
root@hello:/mnt/upload# reboot now
```
### Наличие файлов в каталоге /srv/share/upload/
```
hello@helloubuntu:~$ sudo -i
[sudo] password for hello:
root@helloubuntu:~# ls /srv/share/upload/
111.txt  222.txt
```
### Смотрим экспорты
```
root@helloubuntu:~# exportfs -s
/srv/share  192.168.1.8/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
```
### Смотрим работу RPC
```
root@helloubuntu:~# showmount -a
All mount points on helloubuntu:
192.168.1.8:/srv/share
```
## 4. Проверка со стороны клиента:
### Работа RPC
```
root@hello:/mnt/upload# showmount -a 192.168.1.15
All mount points on 192.168.1.15:
192.168.1.8:/srv/share
```

### Статус монтирования
```
root@hello:/mnt/upload# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=52,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=3508)
192.168.1.15:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=192.168.1.15,mountvers=3,mountport=38643,mountproto=udp,local_lock=none,addr=192.168.1.15)
```
### Создание тестового файла
```
root@hello:/mnt/upload# touch 333.txt
root@hello:/mnt/upload# ls
111.txt  222.txt  333.txt
```
