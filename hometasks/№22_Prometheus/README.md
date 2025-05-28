Сперва скриншоты и немного от себя
![1](screen/1.PNG)
![2](screen/2.PNG)
![3](screen/3.PNG)
![4](screen/4.PNG)
![5](screen/5.PNG)

#Cкачиваем Prometheus
``
hello@helloubuntu:~$ sudo -i
root@helloubuntu:~# cd /home/hello/
root@helloubuntu:/home/hello# wget https://github.com/prometheus/prometheus/releases/download/v3.4.0/prometheus-3.4.0.linux-amd64.tar.gz
``
# Создаем пользователя и нужные каталоги, настраиваем для них владельцев
root@helloubuntu:~#  useradd --no-create-home --shell /bin/false prometheus
root@helloubuntu:~#  mkdir /etc/prometheus
root@helloubuntu:~#  mkdir /var/lib/prometheus
root@helloubuntu:~#  chown prometheus:prometheus /etc/prometheus
root@helloubuntu:~#  chown prometheus:prometheus /var/lib/prometheus
# Распаковываем архив, для удобства переименовываем директорию и копируем бинарники в /usr/local/bin
root@helloubuntu:~# tar -xvzf prometheus-3.4.0.linux-amd64.tar.gz
root@helloubuntu:~# mv prometheus-3.4.0.linux-amd64 prometheuspackage
root@helloubuntu:~# cp prometheuspackage/prometheus /usr/local/bin/
root@helloubuntu:~# cp prometheuspackage/promtool /usr/local/bin/
# Меняем владельцев у бинарников
root@helloubuntu:~# chown prometheus:prometheus /usr/local/bin/prometheus
root@helloubuntu:~# chown prometheus:prometheus /usr/local/bin/promtool
# По аналогии копируем библиотеки
root@helloubuntu:~# cp -r prometheuspackage/consoles /etc/prometheus
root@helloubuntu:~# cp -r prometheuspackage/console_libraries /etc/prometheus
root@helloubuntu:~# chown -R prometheus:prometheus /etc/prometheus/consoles
root@helloubuntu:~# chown -R prometheus:prometheus /etc/prometheus/console_libraries
# Создаем файл конфигурации
$ vim /etc/prometheus/prometheus.yml
global:
 scrape_interval: 10s
scrape_configs:
 - job_name: 'prometheus_master'
 scrape_interval: 5s
 static_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s.
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'wmi_exporter'
    static_configs:
      - targets: ['192.168.1.12:9100']
# Настраиваем сервис
nano /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
--config.file /etc/prometheus/prometheus.yml \
--storage.tsdb.path /var/lib/prometheus/ \
--web.console.templates=/etc/prometheus/consoles \
--web.console.libraries=/etc/prometheus/console_libraries
[Install]
WantedBy=multi-user.target
$ systemctl daemon-reload
$ systemctl start prometheus
$ systemctl status prometheus

# Установка grafana
wget https://mirrors.huaweicloud.com/grafana/12.0.0/grafana-enterprise_12.0.0_amd64.deb
$ systemctl daemon-reload
$ systemctl start grafana-server
