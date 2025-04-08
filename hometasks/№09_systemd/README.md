# Инициализация системы. Systemd.
## 1 часть
Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. 
Ключевое слово и файл лога задается в /etc/default/watcher.conf
Пишем сервис и таймер который запускается каждые 30 сек. Дописал точное время срабатывания таймера, путём добавления в файл описания таймера, в раздел Timer - AccuracySec=1us.
Файлы по ДЗ в директрои watcher

## 2 часть 
Устанавливаем spawn-fcgi и необходимые для него пакеты:
```
root@hello:~# apt-get update
root@hello:~# apt install spawn-fcgi php php-cgi php-cli \ apache2 libapache2-mod-fcgid -y
```
необходимо создать файл с настройками для будущего сервиса
```
root@hello:~# touch /etc/spawn-fcgi/fcgi.conf
root@hello:~# nano /etc/spawn-fcgi/fcgi.conf
```
Создаем юнит
```
root@hello:~# touch /etc/systemd/system/spawn-fcgi.service
root@hello:~# nano /etc/systemd/system/spawn-fcgi.service

SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u www-data -g www-data -s $SOCKET -S -M 0600 -C 32 -F 1 -- /usr/bin/php-cgi"

[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/spawn-fcgi/fcgi.conf
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target
```
Убеждаемся, что все успешно работает:
```
root@hello:~#  systemctl start spawn-fcgi
root@hello:~#  systemctl status spawn-fcgi

● spawn-fcgi.service - Spawn-fcgi startup service by Otus
     Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; preset: enabled)
     Active: active (running) since Tue 2025-04-08 15:38:24 UTC; 1h 36min ago
   Main PID: 11351 (php-cgi)
      Tasks: 33 (limit: 2271)
     Memory: 14.6M (peak: 14.9M)
        CPU: 20ms
     CGroup: /system.slice/spawn-fcgi.service
```
## 3 часть
Установим Nginx из стандартного репозитория:
```
root@hello:~# apt-get update
root@hello:~# apt install nginx -y
```
Mодифицируем исходный service для использования различной конфигурации, а также PID-файлов.
```
root@hello:~# touch /etc/systemd/system/nginx@.service
root@hello:~# nano /etc/systemd/system/nginx@.service
```
Создаем два файла конфигурации nginx-first.conf и nginx-first.conf(файлы приложены в папке ngnix)

Проверим работу:
```
root@hello:~# systemctl start nginx@first
root@hello:~# systemctl start nginx@second
root@hello:~# systemctl status nginx@second
● nginx@second.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/etc/systemd/system/nginx@.service; disabled; preset: enabled)
     Active: active (running) since Tue 2025-04-08 16:24:06 UTC; 55min ago
       Docs: man:nginx(8)
    Process: 13597 ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx-second.conf -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
    Process: 13598 ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx-second.conf -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
   Main PID: 13600 (nginx)
      Tasks: 5 (limit: 2271)
     Memory: 3.8M (peak: 4.3M)
        CPU: 16ms
     CGroup: /system.slice/system-nginx.slice/nginx@second.service
             ├─13600 "nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx-second.conf -g daemon on; master_process on;"
             ├─13601 "nginx: worker process"
             ├─13602 "nginx: worker process"
             ├─13603 "nginx: worker process"
             └─13604 "nginx: worker process"
``` 
