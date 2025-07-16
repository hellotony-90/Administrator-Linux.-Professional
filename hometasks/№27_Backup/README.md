# Borg Backup
## Установка и использование клиента Borg Backup (выполняем и на клиенте и на сервере)
```
root@helloubuntu:~# apt update
root@helloubuntu:~# apt install borgbackup
```
## Cоздать пользователя borg от имени которого будет работать сервер
```
root@hello:~# useradd -m borg
```

## Для аутентификации удаленных клиентов мы будем использовать SSH-ключи, поэтому сразу создадим нужную структуру папок на сервере и файлов и назначим им владельца:
```
root@hello:~# mkdir ~borg/.ssh
root@hello:~# touch ~borg/.ssh/authorized_keys
root@hello:~# chown -R borg:borg ~borg/.ssh
```
## Создадим SSH-ключ на клиенте, от установки парольной фразы для закрытого ключа отказываемся:
```
root@helloubuntu:~# ssh-keygen
Generating public/private ed25519 key pair.
Enter file in which to save the key (/root/.ssh/id_ed25519):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /root/.ssh/id_ed25519
Your public key has been saved in /root/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:v5SCVGdQ9+pZiUmuy3zpd8mZPmQpD9AtZKaalvbqb0g root@helloubuntu
The key's randomart image is:
+--[ED25519 256]--+
|        ... .    |
|         . . =   |
|        . o B o  |
|       . o = * o |
|      . S + * + .|
|     . . E + = + |
|      . = B o.B +|
|         * =o .B.|
|        .oO+...o.|
+----[SHA256]-----+
```
## Просмотрим содержимое ключа
```
root@helloubuntu:~# cat /root/.ssh/id_ed25519.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINKltGEfgqlBNbworEFFoWvPTlgZkg/mpMjuLepJ1Kw1 root@helloubuntu
```
## Добавим открытый ключ клиента на сервер
```
root@hello:~# nano ~borg/.ssh/authorized_keys
echo 'command="/usr/bin/borg serve" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINKltGEfgqlBNbworEFFoWvPTlgZkg/mpMjuLepJ1Kw1' >> ~borg/.ssh/authorized_keys
```
## Вернемся на клиент и создадим новый репозиторий
```
root@helloubuntu:~# borg init -e none borg@192.168.1.12:backup
```
## Сделаем тестовый бекап и проверим его наличие
```
root@helloubuntu:~# borg create -C zstd borg@192.168.1.12:backup::logs-`date +%Y%m%d_%H%M%S` /var/log/auth.log --list
A /var/log/auth.log
root@helloubuntu:~# borg create -C zstd borg@192.168.1.12:backup::logs-`date +%Y%m%d_%H%M%S` /var/log/auth.log --list
A /var/log/auth.log

```
## Создаем юнит службы и юнит таймера
```
root@helloubuntu:~# touch /etc/systemd/system/borg-backup.service
root@helloubuntu:~# touch /etc/systemd/system/borg-backup.timer
```
## Откроем файлы редактором и внесем содержимое 
```
root@helloubuntu:~# nano /etc/systemd/system/borg-backup.service
  GNU nano 7.2                                                        /etc/systemd/system/borg-backup.service
[Unit]
Description=Borg backup
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c "borg create -C zstd borg@192.168.1.12:backup::logs-$(date +%%Y%%m%%d_%%H%%M%%S) /var/log/auth.log"
ExecStart=borg prune --keep-daily 14 --keep-weekly 8 --keep-monthly 12 borg@192.168.1.12:backup
[Install]
WantedBy=multi-user.target
```
```
root@helloubuntu:~# nano /etc/systemd/system/borg-backup.timer
Description=Borg backup timer

[Timer]
OnBootSec=5min
OnUnitActiveSec=1min
Unit=borg-backup.service

[Install]
WantedBy=multi-user.target
```
## Запускаем юнит службы
```
root@helloubuntu:~# systemctl daemon-reload
root@helloubuntu:~# systemctl start borg-backup.service
```
## Смотрим езультат выполнения
```
root@helloubuntu:~# systemctl status borg-backup.service
○ borg-backup.service - Borg backup
     Loaded: loaded (/etc/systemd/system/borg-backup.service; disabled; preset: enabled)
     Active: inactive (dead) since Wed 2025-07-16 17:44:16 UTC; 30s ago
TriggeredBy: ● borg-backup.timer
    Process: 33726 ExecStart=/bin/bash -c borg create -C zstd borg@192.168.1.12:backup::logs-$(date +%Y%m%d_%H%M%S) /var/log/auth.log (code=exited, status=0/SUCCESS)
   Main PID: 33726 (code=exited, status=0/SUCCESS)
        CPU: 196ms

Jul 16 17:44:15 helloubuntu systemd[1]: Starting borg-backup.service - Borg backup...
Jul 16 17:44:16 helloubuntu systemd[1]: borg-backup.service: Deactivated successfully.
Jul 16 17:44:16 helloubuntu systemd[1]: Finished borg-backup.service - Borg backup.

```
## Включаем и запускаем службу таймера
```
systemctl start borg-backup.timer
systemctl enable borg-backup.timer
```
## Список архивов, хранящихся в репозитории
```
root@helloubuntu:~# borg list borg@192.168.1.12:backup
logs-20250716_165821                 Wed, 2025-07-16 16:58:22 [6402887df71bd2c6ac8d6643e7381046a97791be5112f36f5aa3c50395da6a49]
logs-20250716_165921                 Wed, 2025-07-16 16:59:22 [9dd1e638d3bf67ca5ecba6eb0d93dcb11283e9653b21887e8ace1b37be21b489]
logs-20250716_173317                 Wed, 2025-07-16 17:33:18 [8bb1df7c6b51148108fb2376224560afe8c22121ea11c2169ba274cc457281eb]
logs-20250716_173437                 Wed, 2025-07-16 17:34:38 [185cd563ee6a34d458eee0d286f4cee84275febde838f231660f27490d3d667d]
logs-20250716_173617                 Wed, 2025-07-16 17:36:18 [857f63662c58e30f7388bf0a383e4d25fae5180f12b17e65b4c2bda9033db33e]
logs-20250716_173644                 Wed, 2025-07-16 17:36:45 [dca0da65156c1c6a37adf945d665f4715c61eff2aa3406795e8f6c10366b5df6]
logs-20250716_173727                 Wed, 2025-07-16 17:37:28 [b30bc957741ab746920106c1ff2a3c20c45d7e34ba8a77bc2889e3c37c1b0d44]
logs-20250716_174237                 Wed, 2025-07-16 17:42:38 [c6bb0717faf448646de339e866ea58013c34f934c3ca7bb0da5e485314e1a2d3]
logs-20250716_174411                 Wed, 2025-07-16 17:44:12 [2bd4fecc244edc64dd4f75aebbc174e67524de092556b964c729825bdf175bb0]
logs-20250716_174415                 Wed, 2025-07-16 17:44:16 [cbc568f496660d39f002939dd9052928a172e6159b6a4d56a0ba8295f0c3e33d]
logs-20250716_174516                 Wed, 2025-07-16 17:45:17 [979e258df6946a20128ea6ea565a2346231e04b4bd051442ab6e42f7ce96621c]
logs-20250716_174617                 Wed, 2025-07-16 17:46:18 [edab13a1c20a18b35895ed2f53e54962c78f6d89ec7e25f7dd78343f60a2f8dc]
logs-20250716_174727                 Wed, 2025-07-16 17:47:28 [528eb686f60a6eac27c81359c11e20248b5c03394ba7b7900c3adb0b68ad92ea]
logs-20250716_174837                 Wed, 2025-07-16 17:48:38 [0fd2dcf6f46214e4e14210685d50a003239a6f147f4fc461d11d524ba818d774]
logs-20250716_174957                 Wed, 2025-07-16 17:49:58 [90a227112db662a69fd9acf740e79f020e070cd0a33e2e729c6fe67a886db9ba]
logs-20250716_175057                 Wed, 2025-07-16 17:50:58 [09a08f8db73af80e2a401e6bd01b34f664b1f23ec6f63da04afca27361746e1c]
logs-20250716_175207                 Wed, 2025-07-16 17:52:08 [adec35f27d1f6d14272e3fadcd1077c510e9e3cd30148d1540757d1f61697024]
logs-20250716_175317                 Wed, 2025-07-16 17:53:18 [2b6d3470b45e6192cad2a743443181316867c5aa5d794c059c58fd81b3dd2990]
logs-20250716_175427                 Wed, 2025-07-16 17:54:28 [fc5be501ac28d031fe6923212c0feef2e9f4bf83b17bef418fcc785825460616]
logs-20250716_175537                 Wed, 2025-07-16 17:55:39 [2c8f29d7de98a6b0f90a45c563a028e636c3ee5f869bcfca585cdd28552127df]
logs-20250716_175647                 Wed, 2025-07-16 17:56:48 [87af36e98473b7c36a1f434de419d2794841c2aac22a482d201c7f5c12505c50]
logs-20250716_175757                 Wed, 2025-07-16 17:57:58 [1f73ad7f7c67ae6ced2276606727bb3920048bfd751b2fa71570119481e78973]
logs-20250716_175907                 Wed, 2025-07-16 17:59:08 [f3526f90d904ba6c57929681899f3cf8adf658e8c247455245a390ab3163c803]
logs-20250716_180014                 Wed, 2025-07-16 18:00:15 [c59e54e65fa6f87d3c8fb6812955bad78da55d10fb05098c905270de47ebbd99]
logs-20250716_180117                 Wed, 2025-07-16 18:01:18 [02ffad87c4a5c301a06c6abbcfb499261f3a607857fab54d3cb6f3f68de153b5]
logs-20250716_180237                 Wed, 2025-07-16 18:02:38 [0b71ae08034c2c0f21227462ba491533100e79567389ef3bcbad033817b288c4]
logs-20250716_180347                 Wed, 2025-07-16 18:03:48 [d7ae4b10991a87a2e6d233e0adadd5b40cf096310ae45bf960492b96b95e30c1]
logs-20250716_180457                 Wed, 2025-07-16 18:04:59 [b8dcd4cf50983c53132c588937869a7b2d4c1fcc2a0023c0b230cae42ce93958]
```
