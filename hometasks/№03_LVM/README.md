Работа с LVM, расширение LVM, работа со снапшотами выложена в [файл](files/pre-hometask.sh)

# Домашнее задание 

## Уменьшить том под / до 8G
### Подготовим временный том для / раздела:
```
root@hello:~# pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
root@hello:~# vgcreate vg_root /dev/sdb
  Volume group "vg_root" successfully created
root@hello:~# lvcreate -n lv_root -l +100%FREE /dev/vg_root
  Logical volume "lv_root" created.
```
###  Создадим на нем файловую систему и смонтируем его, чтобы перенести туда данные:
```
root@hello:~# mkfs.ext4 /dev/vg_root/lv_root
mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 2620416 4k blocks and 655360 inodes
Filesystem UUID: 40a20541-8f71-4d6d-84cf-b607f0fbaed8
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done
Writing inode tables: done
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done
```
```
root@hello:~# mount /dev/vg_root/lv_root /mnt
```
### Этой командой копируем все данные с / раздела в /mnt:
```
root@hello:~# rsync -avxHAX --progress / /mnt/
sent 4,404,350,596 bytes  received 1,576,352 bytes  160,215,525.38 bytes/sec
total size is 4,401,701,445  speedup is 1.00
```
### Затем сконфигурируем grub для того, чтобы при старте перейти в новый /.
Сымитируем текущий root, сделаем в него chroot и обновим grub:
```
root@hello:~# for i in /proc/ /sys/ /dev/ /run/ /boot/;  do mount --bind $i /mnt/$i; done
root@hello:~# chroot /mnt/
root@hello:/# grub-mkconfig -o /boot/grub/grub.cfg
Sourcing file `/etc/default/grub'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-6.8.0-55-generic
Found initrd image: /boot/initrd.img-6.8.0-55-generic
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
Adding boot menu entry for UEFI Firmware Settings ...
done
```
### Обновим образ initrd. 
```
root@hello:/# update-initramfs -u
update-initramfs: Generating /boot/initrd.img-6.8.0-55-generic
```
```
root@hello:~# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0 15.2G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0 13.4G  0 part
  └─ubuntu--vg-ubuntu--lv 252:1    0   10G  0 lvm
sdb                         8:16   0   10G  0 disk
└─vg_root-lv_root         252:0    0   10G  0 lvm  /
sdc                         8:32   0    2G  0 disk
sdd                         8:48   0    1G  0 disk
sde                         8:64   0    2G  0 disk
sr0                        11:0    1 1024M  0 rom
```
### Теперь нам нужно изменить размер старой VG и вернуть на него рут.
```
root@hello:~#lvremove /dev/ubuntu-vg/ubuntu-lv
root@hello:~#lvcreate -n ubuntu-vg/ubuntu-lv -L 8G /dev/ubuntu-vg
```
### Проделываем на нем те же операции, что и в первый раз:
```
root@hello:~# mkfs.ext4 /dev/ubuntu-vg/ubuntu-lv
```
```
root@hello:~# mount /dev/ubuntu-vg/ubuntu-lv /mnt
```
```
rsync -avxHAX --progress / /mnt/
sent 4,421,335,163 bytes  received 1,576,523 bytes  121,175,662.63 bytes/sec
total size is 4,418,679,723  speedup is 1.00
```
### cконфигурируем grub.
```
root@hello:~# for i in /proc/ /sys/ /dev/ /run/ /boot/; \
 do mount --bind $i /mnt/$i; done
root@hello:~# chroot /mnt/
root@hello:/# grub-mkconfig -o /boot/grub/grub.cfg
Sourcing file `/etc/default/grub'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-6.8.0-55-generic
Found initrd image: /boot/initrd.img-6.8.0-55-generic
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
Adding boot menu entry for UEFI Firmware Settings ...
done
```
### Обновим образ initrd. 
```
update-initramfs: Generating /boot/initrd.img-6.8.0-55-generic
W: Couldn't identify type of root file system for fsck hook
```
### Выделить том под /var в зеркало
```
root@hello:/# pvcreate /dev/sdc /dev/sdd
  Physical volume "/dev/sdc" successfully created.
  Physical volume "/dev/sdd" successfully created.
```
```
root@hello:/# vgcreate vg_var /dev/sdc /dev/sdd
  Volume group "vg_var" successfully created
```
```
root@hello:/# lvcreate -L 950M -m1 -n lv_var vg_var
  Rounding up size to full physical extent 952.00 MiB
  Logical volume "lv_var" created.
```
### Создаем на нем ФС и перемещаем туда /var:
```
root@hello:/#  mkfs.ext4 /dev/vg_var/lv_var
root@hello:/# mount /dev/vg_var/lv_var /mnt
root@hello:/# cp -aR /var/* /mnt/
root@hello:/# mkdir /tmp/oldvar && mv /var/* /tmp/oldvar
```
### Правим fstab для автоматического монтирования /var:
```
echo "`blkid | grep var: | awk '{print $2}'` \
 /var ext4 defaults 0 0" >> /etc/fstab
```
### После чего можно успешно перезагружаться в новый (уменьшенный root) и удалять
временную Volume Group:
```
hello@hello:~$ sudo -i
[sudo] password for hello:
root@hello:~# lvremove /dev/vg_root/lv_root
Do you really want to remove and DISCARD active logical volume vg_root/lv_root? [y/n]: y
  Logical volume "lv_root" successfully removed.
root@hello:~# vgremove /dev/vg_root
  Volume group "vg_root" successfully removed
root@hello:~# pvremove /dev/sdb
  Labels on physical volume "/dev/sdb" successfully wiped.
```
## Выделить том под /home
### Выделяем том под /home по тому же принципу что делали для /var:
```
root@hello:~# lvcreate -n LogVol_Home -L 2G /dev/ubuntu-vg
  Logical volume "LogVol_Home" created.
root@hello:~# mkfs.ext4 /dev/ubuntu-vg/LogVol_Home
mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 524288 4k blocks and 131072 inodes
Filesystem UUID: 7c14cbb8-e41a-4c7d-a923-2bb879d75eb8
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912

Allocating group tables: done
Writing inode tables: done
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done
```
```
root@hello:~# mount /dev/ubuntu-vg/LogVol_Home /mnt/
root@hello:~# cp -aR /home/* /mnt/
root@hello:~# rm -rf /home/*
root@hello:~# umount /mnt
root@hello:~# mount /dev/ubuntu-vg/LogVol_Home /home/
```
### Правим fstab для автоматического монтирования /home:
```
root@hello:~# echo "`blkid | grep Home | awk '{print $2}'` \
 /home xfs defaults 0 0" >> /etc/fstab
```
 ## Работа со снапшотами
### Генерируем файлы в /home/:
```
root@hello:~# touch /home/file{1..20}
root@hello:~# ls /home/
file1   file12  file15  file18  file20  file5  file8  lost+found
file10  file13  file16  file19  file3   file6  file9
file11  file14  file17  file2   file4   file7  hello
```
### Снять снапшот:
```
root@hello:~# lvcreate -L 100MB -s -n home_snap  /dev/ubuntu-vg/LogVol_Home
  Logical volume "home_snap" created.
```
### Удаляем часть файлов 
```
root@hello:~# rm -f /home/file{11..20}
root@hello:~# ls /home/
file1   file2  file4  file6  file8  hello
file10  file3  file5  file7  file9  lost+found
```
### Процесс восстановления из снапшота:
```
root@hello:~# umount /home
root@hello:~# lvconvert --merge /dev/ubuntu-vg/home_snap
  Merging of volume ubuntu-vg/home_snap started.
  ubuntu-vg/LogVol_Home: Merged: 100.00%
```
```
root@hello:~# mount /dev/mapper/ubuntu--vg-LogVol_Home /home
mount: /home: /dev/mapper/ubuntu--vg-LogVol_Home already mounted on /home.
       dmesg(1) may have more information after failed mount system call.
root@hello:~# ls -al /home
total 28
drwxr-xr-x  4 root  root   4096 Apr 20 17:55 .
drwxr-xr-x 23 root  root   4096 Mar 14 17:38 ..
-rw-r--r--  1 root  root      0 Apr 20 17:55 file1
-rw-r--r--  1 root  root      0 Apr 20 17:55 file10
-rw-r--r--  1 root  root      0 Apr 20 17:55 file11
-rw-r--r--  1 root  root      0 Apr 20 17:55 file12
-rw-r--r--  1 root  root      0 Apr 20 17:55 file13
-rw-r--r--  1 root  root      0 Apr 20 17:55 file14
-rw-r--r--  1 root  root      0 Apr 20 17:55 file15
-rw-r--r--  1 root  root      0 Apr 20 17:55 file16
-rw-r--r--  1 root  root      0 Apr 20 17:55 file17
-rw-r--r--  1 root  root      0 Apr 20 17:55 file18
-rw-r--r--  1 root  root      0 Apr 20 17:55 file19
-rw-r--r--  1 root  root      0 Apr 20 17:55 file2
-rw-r--r--  1 root  root      0 Apr 20 17:55 file20
-rw-r--r--  1 root  root      0 Apr 20 17:55 file3
-rw-r--r--  1 root  root      0 Apr 20 17:55 file4
-rw-r--r--  1 root  root      0 Apr 20 17:55 file5
-rw-r--r--  1 root  root      0 Apr 20 17:55 file6
-rw-r--r--  1 root  root      0 Apr 20 17:55 file7
-rw-r--r--  1 root  root      0 Apr 20 17:55 file8
-rw-r--r--  1 root  root      0 Apr 20 17:55 file9
drwxr-x---  4 hello hello  4096 Apr 20 17:32 hello
drwx------  2 root  root  16384 Apr 20 17:55 lost+found
```
```  


 
