# I Определение алгоритма с наилучшим сжатием

## 0. Добавляем в VirtualBox 8 дисков размер 512 Mb

## 1.	Получаем права суперпользователя
hello@hello:~$sudo -i

## 2. Загружаем модуль zfs и создаем pool
apt install zfsutils-linux

## 3. Смотрим список всех дисков
root@hello:~# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0 15.2G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0 13.4G  0 part
  └─ubuntu--vg-ubuntu--lv 252:0    0   10G  0 lvm  /
sdb                         8:16   0  512M  0 disk
sdc                         8:32   0  512M  0 disk
sdd                         8:48   0  512M  0 disk
sde                         8:64   0  512M  0 disk
sdf                         8:80   0  512M  0 disk
sdg                         8:96   0  512M  0 disk
sdh                         8:112  0  512M  0 disk
sdi                         8:128  0  512M  0 disk
sr0                        11:0    1 1024M  0 rom

## 4. Создаём пул из двух дисков в режиме RAID 1:
root@hello:~#zpool create zfs1 mirror /dev/sdb /dev/sdc

## 5. Создадим оставшиеся пулы:
root@hello:~# zpool create zfs2 mirror /dev/sdd /dev/sde
root@hello:~# zpool create zfs3 mirror /dev/sdf /dev/sdg
root@hello:~# zpool create zfs4 mirror /dev/sdh /dev/sdi

## 6. Смотрим информацию о пулах 
root@hello:~# zpool list
NAME   SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
zfs1   480M   123K   480M        -         -     0%     0%  1.00x    ONLINE  -
zfs2   480M   114K   480M        -         -     0%     0%  1.00x    ONLINE  -
zfs3   480M   116K   480M        -         -     0%     0%  1.00x    ONLINE  -
zfs4   480M   108K   480M        -         -     0%     0%  1.00x    ONLINE  -
root@hello:~# zfs get all | egrep compression
zfs1  compression           lzjb                   local
zfs2  compression           lz4                    local
zfs3  compression           gzip-9                 local
zfs4  compression           zle                    local

## 7. В каждую фс скачиваем файл ASR920_HIG.book с яндеск.диск
root@hello:~# for i in {1..4}; do wget -P /zfs$i https://disk.yandex.ru/i/I0fe3-1RqNL0oA; done
root@hello:~# ls -l /zfs*
/zfs1:
total 22
-rw-r--r-- 1 root root 35629 Apr  6 15:58 I0fe3-1RqNL0oA
/zfs2:
total 18
-rw-r--r-- 1 root root 35618 Apr  6 15:58 I0fe3-1RqNL0oA
/zfs3:
total 13
-rw-r--r-- 1 root root 35660 Apr  6 15:58 I0fe3-1RqNL0oA
/zfs4:
total 36
-rw-r--r-- 1 root root 35549 Apr  6 15:58 I0fe3-1RqNL0oA
root@hello:~# zfs list
NAME   USED  AVAIL  REFER  MOUNTPOINT
zfs1   173K   352M  45.5K  /zfs1
zfs2   161K   352M    41K  /zfs2
zfs3   160K   352M    36K  /zfs3
zfs4   174K   352M    59K  /zfs4

## 8. Смотрим сжатие
root@hello:~# zfs get all | grep compressratio | grep -v ref
zfs1  compressratio         1.17x                  -
zfs2  compressratio         1.26x                  -
zfs3  compressratio         1.35x                  -
zfs4  compressratio         1.00x                  -
Алгоритм gzip-9 самый эффективный по сжатию. 


# II Определение настроек пула

## 1. Скачиваем архив
root@hello:~# wget -O archive.tar.gz --no-check-certificate 'https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download'

--2025-04-06 16:15:24--  https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download
Resolving drive.usercontent.google.com (drive.usercontent.google.com)... 209.85.233.132, 2a00:1450:4010:c0a::84
Connecting to drive.usercontent.google.com (drive.usercontent.google.com)|209.85.233.132|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 7275140 (6.9M) [application/octet-stream]
Saving to: ‘archive.tar.gz’
archive.tar.gz            100%[=====================================>]   6.94M  1.37MB/s    in 5.0s
2025-04-06 16:15:38 (1.40 MB/s) - ‘archive.tar.gz’ saved [7275140/7275140]

## 2.Разархивируем его:
root@hello:~# tar -xzvf archive.tar.gz
zpoolexport/
zpoolexport/filea
zpoolexport/fileb

## 3.Проверика, возможности импортирования данного каталога в пул:
root@hello:~# zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
status: Some supported features are not enabled on the pool.
        (Note that they may be intentionally disabled if the
        'compatibility' property is set.)
 action: The pool can be imported using its name or numeric identifier, though
        some features will not be available without an explicit 'zpool upgrade'.
 config:

        otus                         ONLINE
          mirror-0                   ONLINE
            /root/zpoolexport/filea  ONLINE
            /root/zpoolexport/fileb  ONLINE
root@hello:~# zpool import -d zpoolexport/ zfs
cannot import 'zfs': no such pool available
root@hello:~# zpool import -d zpoolexport/ zfs1
cannot import 'zfs1': a pool with that name already exists
use the form 'zpool import <pool | id> <newpool>' to give it a new name
Вывод показывает имя пула, тип raid и его состав. 

## 4. Импорт пула к нам в ОС:
root@hello:~# zpool import -d zpoolexport/ otus
root@hello:~#
zpool status
  pool: otus
 state: ONLINE
status: Some supported and requested features are not enabled on the pool.
        The pool can still be used, but some features are unavailable.
action: Enable all features using 'zpool upgrade'. Once this is done,
        the pool may no longer be accessible by software that does not support
        the features. See zpool-features(7) for details.
config:

        NAME                         STATE     READ WRITE CKSUM
        otus                         ONLINE       0     0     0
          mirror-0                   ONLINE       0     0     0
            /root/zpoolexport/filea  ONLINE       0     0     0
            /root/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors

  pool: zfs1
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        zfs1        ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdb     ONLINE       0     0     0
            sdc     ONLINE       0     0     0

errors: No known data errors

  pool: zfs2
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        zfs2        ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdd     ONLINE       0     0     0
            sde     ONLINE       0     0     0

errors: No known data errors

  pool: zfs3
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        zfs3        ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdf     ONLINE       0     0     0
            sdg     ONLINE       0     0     0

errors: No known data errors

  pool: zfs4
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        zfs4        ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdh     ONLINE       0     0     0
            sdi     ONLINE       0     0     0

errors: No known data errors

root@hello:~# zpool status
  pool: otus
 state: ONLINE
status: Some supported and requested features are not enabled on the pool.
        The pool can still be used, but some features are unavailable.
action: Enable all features using 'zpool upgrade'. Once this is done,
        the pool may no longer be accessible by software that does not support
        the features. See zpool-features(7) for details.
config:

        NAME                         STATE     READ WRITE CKSUM
        otus                         ONLINE       0     0     0
          mirror-0                   ONLINE       0     0     0
            /root/zpoolexport/filea  ONLINE       0     0     0
            /root/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors

  pool: zfs1
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        zfs1        ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdb     ONLINE       0     0     0
            sdc     ONLINE       0     0     0

errors: No known data errors

  pool: zfs2
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        zfs2        ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdd     ONLINE       0     0     0
            sde     ONLINE       0     0     0

errors: No known data errors

  pool: zfs3
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        zfs3        ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdf     ONLINE       0     0     0
            sdg     ONLINE       0     0     0

errors: No known data errors

  pool: zfs4
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        zfs4        ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdh     ONLINE       0     0     0
            sdi     ONLINE       0     0     0

errors: No known data errors




# III Работа со снапшотом, поиск сообщения от преподавателя

## 1.Скачаем файл, указанный в задании:
root@hello:~# wget -O otus_task2.file --no-check-certificate https://drive.usercontent.google.com/download?id=1wgxjih8YZ-cqLqaZVa0lA3h3Y029c3oI&export=download

## 2.Восстановим файловую систему из снапшота:
root@hello:~# zfs receive otus/test@today < otus_task2.file

## 3.ищем в каталоге /otus/test файл с именем “secret_message”:
root@hello:~# find /otus/test/ -name "secret_message"
/otus/test/task1/file_mess/secret_message

4.Cмотрим содержимое найденного файла:
root@hello:~# cat /otus/test/task1/file_mess/secret_message
https://otus.ru/lessons/linux-hl/
