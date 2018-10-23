#!/bin/sh

yum install -y gcc zlib-devel readline-devel
yum install -y https://download.postgresql.org/pub/repos/yum/9.3/redhat/rhel-7-x86_64/pgdg-centos93-9.3-3.noarch.rpm
yum install -y https://download.postgresql.org/pub/repos/yum/9.4/redhat/rhel-7-x86_64/pgdg-centos94-9.4-3.noarch.rpm
yum install -y https://download.postgresql.org/pub/repos/yum/9.5/redhat/rhel-7-x86_64/pgdg-centos95-9.5-3.noarch.rpm
yum install -y https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm
yum install -y postgresql93-server postgresql93-contrib
yum install -y postgresql94-server postgresql94-contrib
yum install -y postgresql95-server postgresql95-contrib
yum install -y postgresql96-server postgresql96-contrib

ln -s /usr/pgsql-9.3/lib/libpq.so.5.6 /usr/pgsql-9.3/lib/libpq.so
ln -s /usr/pgsql-9.4/lib/libpq.so.5.7 /usr/pgsql-9.4/lib/libpq.so
ln -s /usr/pgsql-9.5/lib/libpq.so.5.8 /usr/pgsql-9.5/lib/libpq.so
ln -s /usr/pgsql-9.6/lib/libpq.so.5.9 /usr/pgsql-9.6/lib/libpq.so

mkdir source
cd source
wget https://ftp.postgresql.org/pub/source/v10.3/postgresql-10.3.tar.gz
wget https://ftp.postgresql.org/pub/source/v10.4/postgresql-10.4.tar.gz
wget https://ftp.postgresql.org/pub/source/v10.5/postgresql-10.5.tar.gz
wget https://ftp.postgresql.org/pub/source/v10.2/postgresql-10.2.tar.gz
wget https://ftp.postgresql.org/pub/source/v10.1/postgresql-10.1.tar.gz

gunzip < postgresql-10.1.tar.gz | tar xf -
gunzip < postgresql-10.2.tar.gz | tar xf -
gunzip < postgresql-10.3.tar.gz | tar xf -
gunzip < postgresql-10.4.tar.gz | tar xf -
gunzip < postgresql-10.5.tar.gz | tar xf -

cd postgresql-10.1
./configure --prefix=/opt/PostgreSQL-10.1
make
make install
cd ..
cd postgresql-10.2
./configure --prefix=/opt/PostgreSQL-10.2
make
make install
cd ..
cd postgresql-10.3
./configure --prefix=/opt/PostgreSQL-10.3
make
make install
cd ..
cd postgresql-10.4
./configure --prefix=/opt/PostgreSQL-10.4
make
make install
cd ..
cd postgresql-10.5
./configure --prefix=/opt/PostgreSQL-10.5
make
make install
cd ..
cd ..
rm -rf source
yum install -y mono-complete-5.10.1.20
