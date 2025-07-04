# Сбор и хранение логов 
## Задание
Поднимаем 2е виртуальные машины
на web поднимаем nginx
на log настраиваем центральный лог сервер
настраиваем аудит, следящий за изменением конфигов nginx
### Настройки LOG-сервера
#### Проверяем наличие rsyslog
```
root@log:~# apt list rsyslog
```
#### Раскомментируем строчки в настройках rsyslog
```
root@log:~# nano /etc/rsyslog.conf
```
```
module(load="imudp")
input(type="imudp" port="514")
module(load="imtcp")
input(type="imtcp" port="514")
```
```
# Добавляем правила приёма сообщений от хостов
$template RemoteLogs,"/var/log/rsyslog/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteLogs
& ~
```
#### Рестартуем сервис и смотрим появились ли открытые порты
```
root@log:~# systemctl restart rsyslog.service
root@log:~# ss -tunlp
Netid State  Recv-Q Send-Q       Local Address:Port Peer Address:PortProcess
udp   UNCONN 0      0      192.168.1.18%enp0s3:68        0.0.0.0:*    users:(("systemd-network",pid=558,fd=22))
udp   UNCONN 0      0                  0.0.0.0:514       0.0.0.0:*    users:(("rsyslogd",pid=1035,fd=5))
udp   UNCONN 0      0               127.0.0.54:53        0.0.0.0:*    users:(("systemd-resolve",pid=570,fd=16))
udp   UNCONN 0      0            127.0.0.53%lo:53        0.0.0.0:*    users:(("systemd-resolve",pid=570,fd=14))
udp   UNCONN 0      0                     [::]:514          [::]:*    users:(("rsyslogd",pid=1035,fd=6))
tcp   LISTEN 0      4096         127.0.0.53%lo:53        0.0.0.0:*    users:(("systemd-resolve",pid=570,fd=15))
tcp   LISTEN 0      25                 0.0.0.0:514       0.0.0.0:*    users:(("rsyslogd",pid=1035,fd=7))
tcp   LISTEN 0      4096            127.0.0.54:53        0.0.0.0:*    users:(("systemd-resolve",pid=570,fd=17))
tcp   LISTEN 0      4096                     *:22              *:*    users:(("sshd",pid=820,fd=3),("systemd",pid=1,fd=89))
tcp   LISTEN 0      25                    [::]:514          [::]:*    users:(("rsyslogd",pid=1035,fd=8))
```
## Настройки WEB
#### Устанавливаем nginx
```
root@web:~# apt update && apt install -y nginx
```
#### Проверяем его статус и версию
```
root@web:~# systemctl status nginx.service
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: enabled)
     Active: active (running) since Thu 2025-07-03 18:15:45 UTC; 36s ago
       Docs: man:nginx(8)
    Process: 1469 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
    Process: 1471 ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
   Main PID: 1500 (nginx)
      Tasks: 2 (limit: 2268)
     Memory: 1.7M (peak: 3.7M)
        CPU: 6ms
     CGroup: /system.slice/nginx.service
             ├─1500 "nginx: master process /usr/sbin/nginx -g daemon on; master_process on;"
             └─1502 "nginx: worker process"

Jul 03 18:15:45 web systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Jul 03 18:15:45 web systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.
root@web:~# nginx -v
nginx version: nginx/1.24.0 (Ubuntu)
```
#### Редактируем nginx.conf
```
root@web:~# nano /etc/nginx/nginx.conf
```
```
error_log syslog:server=192.168.1.18:514,tag=nginx_error;
access_log syslog:server=192.168.1.18:514,tag=nginx_access,severity=info combined;
```
#### Проверяем конфигурацию nginx и рестартуем службу
```
root@web:~# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```
```
root@web:~# systemctl restart nginx.service
```
#### Тестирование
##### Подключаемся с web-серверу и смотри логи access
```
root@log:~# cat /var/log/rsyslog/web/nginx_access.log
2025-07-03T18:30:16+00:00 web nginx_access: 192.168.1.9 - - [03/Jul/2025:18:30:16 +0000] "GET /favicon.ico HTTP/1.1" 404 196 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 YaBrowser/25.6.0.0 Safari/537.36"
2025-07-03T18:30:17+00:00 web nginx_access: 192.168.1.9 - - [03/Jul/2025:18:30:17 +0000] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 YaBrowser/25.6.0.0 Safari/537.36"
```
##### Делаем манипуляции с web-сервером и смотрим логи error
###### Перемещаем файл веб-страницы, для появления ошибки
```
root@web:~# mv /var/www/html/index.nginx-debian.html /var/www/
```
###### Смотрим log
```
root@log:~# cat /var/log/rsyslog/web/nginx_error.log
2025-07-03T18:31:45+00:00 web nginx_error: 2025/07/03 18:31:45 [error] 1669#1669: *4 directory index of "/var/www/html/" is forbidden, client: 192.168.1.9, server: _, request: "GET / HTTP/1.1", host: "192.168.1.17"
```
