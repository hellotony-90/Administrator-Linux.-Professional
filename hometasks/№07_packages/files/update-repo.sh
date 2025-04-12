#!/bin/sh
# рабочая директория
repodir=/var/www/html/repo/
# наш gpg-ключ
gpgKey="B5573C41438B44940861A54FDB49F83CB008892D"
cd ${repodir}
# Создание индексов
dpkg-scanpackages -m . > Packages
cat Packages | gzip -9c > Packages.gz
# Создание файла релиза
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
