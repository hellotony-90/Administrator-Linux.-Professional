# Ansible
## Схема стенда(простенькая, но протоколировать надо)
![1](screen/1.PNG)
## Подготовка Ansible сервера
```
root@ansibleserver:~# apt update
root@ansibleserver:~# apt install ansible
```
## Проверка версии установленной версии
```
root@ansibleserver:~# ansible --version
ansible [core 2.16.3]
  config file = None
  configured module search path = ['/root/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python3/dist-packages/ansible
  ansible collection location = /root/.ansible/collections:/usr/share/ansible/collections
  executable location = /usr/bin/ansible
  python version = 3.12.3 (main, Jun 18 2025, 17:59:45) [GCC 13.3.0] (/usr/bin/python3)
  jinja version = 3.1.2
  libyaml = True
```
## Создание файла inventory 
```
root@ansibleserver:~/ansible-inventory/templates# nano /root/ansible-inventory/inv.inventory
[test_servers]
server1 ansible_ssh_host=192.168.1.23 ansible_ssh_user=hello
```
## Проверка доступности/uptime
```
root@ansibleserver:~/ansible-inventory# ansible -m ping test_servers -i /root/ansible-inventory/inv.inventory
server1 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}

root@ansibleserver:~/ansible-inventory# ansible -a 'uptime' test_servers -i /root/ansible-inventory/inv.inventory
server1 | CHANGED | rc=0 >>
 13:21:37 up 34 min,  2 users,  load average: 0.00, 0.00, 
```
## Создание плейбука для установки web-сервера замены порта на 8080 и его рестарта
```
root@ansibleserver:~/ansible-inventory/templates# cat /root/ansible-playbooks/nginx.yml
- name: Установка
  hosts: test_servers
  remote_user: hello
  become: true
  vars:
    nginx_listen_port: 8080
  tasks:
  -  name: nginx
     apt:
        name: nginx
        state: latest
  - name: NGINX | Create NGINX config file from template
    template:
       src: nginx.conf.j2
       dest: /etc/nginx/nginx.conf
    tags:
      - nginx-configuration
  - name: Restart nginx service
    service:
        name: nginx
        state: restarted
```
## Создание файла jinja2
```
root@ansibleserver:~/ansible-inventory/templates# nano /root/ansible-playbooks/nginx.conf.j2
events {
}
http {
server {
    listen 8080;

    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
    }
}
}
```
## Проверка web-сервера
```
root@nginx:~# ss -tunl | grep 8080
tcp   LISTEN 0      511                0.0.0.0:8080      0.0.0.0:*
```
![2](screen/2.PNG)
