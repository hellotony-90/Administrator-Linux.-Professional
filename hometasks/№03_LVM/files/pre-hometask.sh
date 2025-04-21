root@hello:~# lvmdiskscan
  /dev/sda2 [       1.75 GiB]
  /dev/sda3 [     <13.42 GiB] LVM physical volume
  /dev/sdb  [      10.00 GiB]
  /dev/sdc  [       2.00 GiB]
  /dev/sdd  [       1.00 GiB]
  /dev/sde  [       1.00 GiB]
  4 disks
  1 partition
  0 LVM physical volume whole disks
  1 LVM physical volume

Для начала разметим диск для будущего использования LVM - создадим PV:

root@hello:~# pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.

Затем можно создавать первый уровень абстракции - VG:
root@hello:~# vgcreate otus /dev/sdb
  Volume group "otus" successfully created
 
И в итоге создать Logical Volume (далее - LV):
 
root@hello:~# lvcreate -l+80%FREE -n test otus
  Logical volume "test" created.

Посмотреть информацию о только что созданном Volume Group:

root@hello:~# vgdisplay otus
  --- Volume group ---
  VG Name               otus
  System ID
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  2
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                1
  Open LV               0
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <10.00 GiB
  PE Size               4.00 MiB
  Total PE              2559
  Alloc PE / Size       2047 / <8.00 GiB
  Free  PE / Size       512 / 2.00 GiB
  VG UUID               6WDtMN-vaLj-wzAT-ljAv-Hzjl-mpWP-RANCG6


посмотреть информацию о том, какие диски входит в VG:

root@hello:~# vgdisplay -v otus | grep 'PV Name'
  PV Name               /dev/sdb

Для начала так же необходимо создать PV:

root@hello:~# pvcreate /dev/sdc
  Physical volume "/dev/sdc" successfully created.
  
  Далее необходимо расширить VG добавив в него этот диск.

root@hello:~# vgextend otus /dev/sdc
  Volume group "otus" successfully extended
Убедимся что новый диск присутствует в новой VG:

root@hello:~# vgdisplay -v otus | grep 'PV Name'
  PV Name               /dev/sdb
  PV Name               /dev/sdc

личиваем LV за счет появившегося свободного места. Возьмем не все место — это для того, чтобы осталось место для демонстрации снапшотов:


root@hello:~# lvextend -l+80%FREE /dev/otus/test
  Size of logical volume otus/test changed from <8.00 GiB (2047 extents) to <11.20 GiB (2866 extents).
  Logical volume otus/test successfully resized.

аблюдаем, что LV расширен до 11.12g:

lvs /dev/otus/test
  LV   VG   Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  test otus -wi-a----- <11.20g             
  
  root@hello:~# mkfs.ext4 /dev/otus/test
mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 2934784 4k blocks and 734400 inodes
Filesystem UUID: be3a2c2c-8f9a-4939-98f4-e0fe84ffe122
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208

Allocating group tables: done
Writing inode tables: done
Creating journal (16384 blocks):
done
Writing superblocks and filesystem accounting information: done

root@hello:~#
root@hello:~#  mkdir /data
root@hello:~# mount /dev/otus/test /data/
root@hello:~# mount | grep /data
/dev/mapper/otus-test on /data type ext4 (rw,relatime)

Допустим Вы забыли оставить место на снапшоты. Можно уменьшить существующий LV с помощью команды lvreduce, но перед этим необходимо отмонтировать файловую систему, проверить её на ошибки и уменьшить ее размер:

root@hello:~# umount /data/


root@hello:~# e2fsck -fy /dev/otus/test
e2fsck 1.47.0 (5-Feb-2023)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/otus/test: 11/734400 files (0.0% non-contiguous), 72740/2934784 blocks


root@hello:~# resize2fs /dev/otus/test 10G
resize2fs 1.47.0 (5-Feb-2023)
Resizing the filesystem on /dev/otus/test to 2621440 (4k) blocks.
The filesystem on /dev/otus/test is now 2621440 (4k) blocks long.


oot@hello:~# lvreduce /dev/otus/test -L 10G
  WARNING: Reducing active logical volume to 10.00 GiB.
  THIS MAY DESTROY YOUR DATA (filesystem etc.)
Do you really want to reduce otus/test? [y/n]: Y
  Size of logical volume otus/test changed from <11.20 GiB (2866 extents) to 10.00 GiB (2560 extents).
  Logical volume otus/test successfully resized.

Убедимся, что ФС и lvm необходимого размера:



root@hello:~# df -Th /data/
Filesystem                        Type  Size  Used Avail Use% Mounted on
/dev/mapper/ubuntu--vg-ubuntu--lv ext4  9.8G  4.3G  5.0G  47% /

root@hello:~# lvs /dev/otus/test
  LV   VG   Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  test otus -wi-a----- 10.00g


Работа со снапшотами
Снапшот создается командой lvcreate, только с флагом -s, который указывает на то, что это снимок:
root@hello:~# lvcreate -L 500M -s -n test-snap /dev/otus/test
  Logical volume "test-snap" created.


Провера с помощью VGS

root@hello:~# vgs -o +lv_size,lv_name | grep test
  otus        2   2   1 wz--n- 11.99g 1.50g  10.00g test
  otus        2   2   1 wz--n- 11.99g 1.50g 500.00m test-snap


Снапшот можно смонтировать как и любой другой LV:


root@hello:~# mkdir /data-snap
root@hello:~# mount /dev/otus/test-snap /data-snap/
root@hello:~# ll /data-snap/
total 24
drwxr-xr-x  3 root root  4096 Apr 20 17:09 ./
drwxr-xr-x 25 root root  4096 Apr 20 17:18 ../
drwx------  2 root root 16384 Apr 20 17:09 lost+found/
