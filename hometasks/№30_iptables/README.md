## Работа с Knockd
### Установка
```
root@central:~# apt install knockd
root@central:~# nano /etc/knockd.conf
[options]
        UseSyslog

[openSSH]
        sequence    = 7000,8000,9000
        seq_timeout = 10
        command     = /sbin/iptables -I INPUT -p tcp --dport 22 -j ACCEPT
        tcpflags    = syn

[closeSSH]
        sequence    = 9000,8000,7000
        seq_timeout = 5
        command     = /sbin/iptables -D INPUT -p tcp --dport 22 -j ACCEPT
        tcpflags    = syn

root@central:~# iptables --version
iptables v1.8.10 (nf_tables)
root@central:~# iptables -A INPUT -i enp0s8 -m state --state ESTABLISHED,RELATED -j ACCEPT
root@central:~# iptables -A INPUT -i enp0s8 -j DROP

root@central:~#nano /etc/default/knockd

# control if we start knockd at init or not
# 1 = start
# anything else = don't start
# PLEASE EDIT /etc/knockd.conf BEFORE ENABLING
START_KNOCKD=0

# command line options
KNOCKD_OPTS="-i enp0s8"

root@central:~# systemctl start knockd.service
root@central:~# systemctl status knockd.service
```
```
root@inetrouter2:~# knock 10.10.10.1 7000 8000 9000


root@central:~#  systemctl status knockd.service
● knockd.service - Port-Knock Daemon
     Loaded: loaded (/usr/lib/systemd/system/knockd.service; enabled; preset: enabled)
     Active: active (running) since Sat 2025-07-19 11:56:35 UTC; 2h 4min ago
       Docs: man:knockd(1)
    Process: 1195 ExecReload=/bin/kill -HUP $MAINPID (code=exited, status=0/SUCCESS)
   Main PID: 1100 (knockd)
      Tasks: 1 (limit: 2268)
     Memory: 820.0K (peak: 1.8M)
        CPU: 37ms
     CGroup: /system.slice/knockd.service
             └─1100 /usr/sbin/knockd -i enp0s8

Jul 19 12:14:53 central systemd[1]: Reloading knockd.service - Port-Knock Daemon...
Jul 19 12:14:53 central knockd[1100]: re-reading config file: /etc/knockd.conf
Jul 19 12:14:53 central knockd[1100]: re-opening log file:
Jul 19 12:14:53 central systemd[1]: Reloaded knockd.service - Port-Knock Daemon.
Jul 19 12:14:53 central knockd[1100]: warning: cannot open logfile: No such file or directory
Jul 19 12:14:58 central knockd[1100]: 10.10.10.2: openSSH: Stage 1
Jul 19 12:14:58 central knockd[1100]: 10.10.10.2: openSSH: Stage 2
Jul 19 12:14:58 central knockd[1100]: 10.10.10.2: openSSH: Stage 3
Jul 19 12:14:58 central knockd[1100]: 10.10.10.2: openSSH: OPEN SESAME
Jul 19 12:14:58 central knockd[1199]: openSSH: running command: /sbin/iptables -I INPUT -p tcp --dport 22 -j ACCEPT


root@inetrouter2:~# telnet 10.10.10.1 22
Trying 10.10.10.1...
Connected to 10.10.10.1.
Escape character is '^]'.
SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.12

```
