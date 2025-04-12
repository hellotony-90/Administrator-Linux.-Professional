# Управление пакетами. Дистрибьюция софта
## Планирование репозтория
### Версия linux
```
root@helloubuntu: lsb_release -a
Distributor ID: Ubuntu
Description:    Ubuntu 24.04.2 LTS
Release:        24.04
Codename:       noble
```
### Необходимые пакеты 
 - lighttpd
 - GPG
 - dpkg-dev
 - rng-tools

### Repo generation script: /usr/bin/update-repo.sh

### Установка web сервера

apt-get install lighttpd
# enable directory listing
echo 'server.dir-listing = "enable"' > /etc/lighttpd/conf-enabled/dir-listing.conf
# start lighhttpd and enable autostrt
systemctl restart lighttpd
systemctl enable lighttpd
# create dir for repo
mkdir -p /var/www/html/repo/deb-packages/

Загрузка пакета (брал первый попавшийся с debian.org)
root@helloubuntu:~# ls /var/www/html/repo/deb-packages
root@helloubuntu:~# cd /var/www/html/repo/deb-packages
root@helloubuntu:/var/www/html/repo/deb-packages# wget http://ftp.us.debian.org/debian/pool/main/z/zeroinstall-injector/0install-core_2.18-2_i386.deb

gpg-key generation

root@repo:~# gpg --list-keys
gpg: directory '/root/.gnupg' created
gpg: keybox '/root/.gnupg/pubring.kbx' created
gpg: /root/.gnupg/trustdb.gpg: trustdb created

creating script for repo generation

cat >~/.gnupg/aptRepo <<EOF
%echo Generating a basic OpenPGP key
Key-Type: RSA
Key-Length: 3072
Subkey-Type: ELG-E
Subkey-Length: 3072
Name-Real: apt tech user
Name-Comment: without passphrase
Name-Email: apt@email.non
Expire-Date: 0
%echo done
EOF

root@helloubuntu:~# gpg --batch --gen-key ~/.gnupg/aptRepo
gpg: Generating a basic OpenPGP key
gpg: done
gpg: directory '/root/.gnupg/openpgp-revocs.d' created
gpg: revocation certificate stored as '/root/.gnupg/openpgp-revocs.d/B5573C41438B44940861A54FDB49F83CB008892D.rev'


root@helloubuntu:~# gpg --list-keys
gpg: checking the trustdb
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
/root/.gnupg/pubring.kbx
------------------------
pub   rsa3072 2025-04-12 [SCEAR]
      B5573C41438B44940861A54FDB49F83CB008892D
uid           [ultimate] Anton (without passphrase) <repo@test.com>
sub   elg3072 2025-04-12 [E]

root@helloubuntu:~# gpg --export -a B5573C41438B44940861A54FDB49F83CB008892D > /var/www/html/repo/boozlachuRepo.gpg

root@helloubuntu:~# updatescript=/usr/bin/update-repo.sh
cat <<'EOFSH' >${updatescript}
#!/bin/sh

# working directory
repodir=/var/www/html/repo/
# GPG key
gpgKey="B5573C41438B44940861A54FDB49F83CB008892D"
cd ${repodir}
# create the package index
dpkg-scanpackages -m . > Packages
cat Packages | gzip -9c > Packages.gz
# create the Release file
PKGS=$(wc -c Packages)
PKGS_GZ=$(wc -c Packages.gz)
cat <<EOF > Release
Architectures: all
Date: $(date -R -u)
MD5Sum:
 $(md5sum Packages  | cut -d" " -f1) $PKGS
 $(md5sum Packages.gz  | cut -d" " -f1) $PKGS_GZ
SHA1:
 $(sha1sum Packages  | cut -d" " -f1) $PKGS
 $(sha1sum Packages.gz  | cut -d" " -f1) $PKGS_GZ
SHA256:
 $(sha256sum Packages | cut -d" " -f1) $PKGS
 $(sha256sum Packages.gz | cut -d" " -f1) $PKGS_GZ
EOF
gpg --yes -u $gpgKey --sign -bao Release.gpg Release
EOFSH
chmod 755 ${updatescript}

install the dpkg-scanpackages util:
apt-get install dpkg-dev

add your deb-packages to /var/www/html/repo/deb-packages

run the creation script /usr/bin/update-repo.sh


## Проверка 


root@helloubuntu:/var/www/html/repo/deb-packages# curl localhost/repo/deb-packages/


