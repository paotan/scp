[Create database]
createuser -e -s pgsql -U postgres
createuser -e -S -d -R mydlink -U pgsql
psql -U pgsql -d postgres -c "ALTER USER mydlink WITH PASSWORD 'mydlink@dlink'"
createdb mydlink -O mydlink -U pgsql --encoding UTF8 --lc-ctype en_US.UTF-8 --lc-collate en_US.UTF-8 --template template0
createdb openapi -O mydlink -U pgsql --encoding UTF8 --lc-ctype en_US.UTF-8 --lc-collate en_US.UTF-8 --template template0
dropdb mydlink
psql -l

[initialize database]
su - postgres
rm -rf /usr/local/pgsql/data  # 刪除DB file
initdb -D /usr/local/pgsql/data
postgres -D /usr/local/pgsql/data &

[change password to varchar (64)]
 psql -U mydlink -d openapi << ALTER TABLE device ALTER COLUMN device_password SET DATA TYPE varchar(64);

[import DB schema & data]
psql -U mydlink -d openapi < ./20150611_openapi.schema
psql -U mydlink -d mydlink < ./20150611.schema
psql -U mydlink -d openapi < ./20150611_openapi_initial_data.dump-utf8
psql -U mydlink -d mydlink < ./20150611_initial_data.dump-utf8
sed -i 's/min-provisioned-reads: 50/min-provisioned-reads: 1/g' ./*.conf
sed -i 's/min-provisioned-writes: 50/min-provisioned-writes: 1/g' ./*.conf
/etc/init.d/$ENV-$LOCATION-dynamic_ddb restart

[DB config]
/var/lib/pgsql/data/pg_hba.conf
service postgresql restart

[SQL CLI]
su - postgres
-bash-3.2$ psql mydlink
postgres=# SELECT pg_database_size('mydlink');
SELECT table_schema,table_name FROM information_schema.tables ORDER BY table_schema,table_name;




#!/bin/bash
clear
starttime=`date '+%H:%M'`

echo '=== Extract DB sample data ==='
echo 'Starting'
bzip2 -d < 20150521_RDV2_init_data.tar.bz2 | tar xvf -
echo '== Extract DB Done! =='

echo '=== Convert DB data to UTF-8 ==='
echo 'Starting'
/usr/bin/iconv -f latin1 -t utf-8 20150521_openapi_initial_data.dump > 20150521_openapi_initial_data.dump-utf8
/usr/bin/iconv -f latin1 -t utf-8 20150521_initial_data.dump > 20150521_initial_data.dump-utf8
ls -la *utf8
echo '== Convert to UTF-8 Done! =='

echo '=== create DB ==='
echo 'Starting'
/usr/bin/createdb mydlink -O mydlink -U pgsql --encoding UTF8 --lc-ctype en_US.UTF-8 --lc-collate en_US.UTF-8 --template template0
/usr/bin/createdb openapi -O mydlink -U pgsql --encoding UTF8 --lc-ctype en_US.UTF-8 --lc-collate en_US.UTF-8 --template template0
echo '== Create DB Done! =='

echo '=== import DB ==='
echo 'Starting'
/usr/bin/psql -U mydlink -d openapi < 20150521_openapi.schema
/usr/bin/psql -U mydlink -d mydlink < 20150521.schema
/usr/bin/psql -U mydlink -d openapi < 20150521_openapi_initial_data.dump-utf8
/usr/bin/psql -U mydlink -d mydlink < 20150521_initial_data.dump-utf8
echo '==== Import DB process Finished! ===='

stoptime=`date '+%H:%M'`

echo "== DB import job starts from \"${starttime}\" to \"${stoptime}\" =="

#!/bin/bash

DB_SAMPLE_NAME=20150521_RDV2_init_data.tar.bz2
clear

echo '=== Extract DB sample data ==='
read -p "Press [Enter] key to start!"
echo 'Starting'
bzip2 -d < 20150521_RDV2_init_data.tar.bz2 | tar xvf -
ls -latr
echo '== Extract DB Done! =='
echo '=== Convert DB data to UTF-8 ==='
read -p "Press [Enter] key to start!"
echo 'Starting'
/usr/bin/iconv -f latin1 -t utf-8 20150521_openapi_initial_data.dump > 20150521_openapi_initial_data.dump-utf8
/usr/bin/iconv -f latin1 -t utf-8 20150521_initial_data.dump > 20150521_initial_data.dump-utf8
ls -latr
echo '== Convert to UTF-8 Done! =='
read -p "Press [Enter] key to start!"
echo '=== create DB ==='
echo 'Starting'
/usr/bin/createdb mydlink -O mydlink -U pgsql --encoding UTF8 --lc-ctype en_US.UTF-8 --lc-collate en_US.UTF-8 --template template0
/usr/bin/createdb openapi -O mydlink -U pgsql --encoding UTF8 --lc-ctype en_US.UTF-8 --lc-collate en_US.UTF-8 --template template0
echo '== Create DB Done! =='
read -p "Press [Enter] key to start!"
echo '=== import DB ==='
echo 'Starting'
/usr/bin/psql -U mydlink -d openapi < 20150521_openapi.schema
/usr/bin/psql -U mydlink -d mydlink < 20150521.schema
/usr/bin/psql -U mydlink -d openapi < 20150521_openapi_initial_data.dump-utf8
/usr/bin/psql -U mydlink -d mydlink < 20150521_initial_data.dump-utf8
echo '==== Import DB process Finished! ===='

#!/bin/bash
#
# dump schema from *SAMPLE SITE*,
# dump device, device_network, email template tables from *SAMPLE SITE*.
#
# Usage: execute this script in *SAMPLE SITE* will create 2 files with date.
#        copy these two files to *NEW SITE*.
#        psql -U mydlink -d mydlink < {DATE}.schema
#        psql -U mydlink -d mydlink < {DATE}_initial_data.dump
#
# Example:
#      on *SAMPLE SITE*
#          1. sh create_initial_data.sh
#          2. copy 20110118.dump 20110118.schema to *NEW SITE*
#      on *NEW SITE*
#          1. createdb -U pgsql -O mydlink
#          2. psql -U mydlink -d mydlink < 20110118.scheam
#          3. psql -U mydlink -d mydlink < 20110118.dump
#

#####################################
### Dump initial data from RD(V2) ###
#####################################
# 20150612  v1.4.0 - 1. Change file name.
#                    2. Add copy & clean up actions.
#                    3. Marked delete backup tarball files.
# 20150611  v1.3.0 - Add more useful setting and progress bar.
# 20150326  v1.2.0 - Add to dump 'sku' data for init usage.
# 20141126  v1.1.0 - Add '--encoding utf8' parameter.
# xxxxxxxx  v1.0.0 - First release for mydlink v2.4 version.
#####################################

clear

export NOW=`date +%Y%m%d`
export PGPASSWORD="mydlink@dlink"
export DATA_temp="/home/paul_tung/DBBackup/data"
export RDFS_temp="/home/paul_tung/DBBackup/RDFS_temp"

### Echo message and progress bar
echo -e "\n\nDump \e[1mRD(V2)\e[0m initial data now ..."
echo -ne "*                    * (  0%)\r"

### Ensure export folder exists
if [[ ! -d ${DATA_temp} ]]; then
  /bin/mkdir -p ${DATA_temp}
fi

### Check folder exists & already mount to RD fileserver (10.32.38.1)
if [[ ! -d ${RDFS_temp} ]]; then
  mkdir -p ${RDFS_temp}
  sudo mount -t cifs -o username=paul_tung,password=1234qwer,iocharset=utf8,code=cp950 //10.32.38.1/temp ${RDFS_temp}
else
  if [[ ! `mount|grep ${RDFS_temp}` ]]; then
    sudo mount -t cifs -o username=paul_tung,password=1234qwer,iocharset=utf8,code=cp950 //10.32.38.1/temp ${RDFS_temp}
  fi
fi
echo -ne "*#                   * (  5%)\r"

### Dump 'mydlink' schema only
/usr/local/pgsql/bin/pg_dump -U mydlink mydlink --encoding utf8 --schema-only > ${DATA_temp}/${NOW}.schema
echo -ne "*##                  * ( 10%)\r"

### Dump 'mydlink' data only
/usr/local/pgsql/bin/pg_dump -U mydlink mydlink --encoding utf8 --data-only \
    -t device \
    -t sf_guard_permission \
    -t md_application \
    -t oauth_service \
    -t sku \
    > ${DATA_temp}/${NOW}_initial_data.dump
echo -ne "*######              * ( 30%)\r"

### Dump 'openapi' schema only
/usr/local/pgsql/bin/pg_dump -U mydlink openapi --encoding utf8 --schema-only > ${DATA_temp}/${NOW}_openapi.schema
echo -ne "*########            * ( 40%)\r"

### Dump 'openapi' data only
/usr/local/pgsql/bin/pg_dump -U mydlink openapi --encoding utf8 --data-only \
    -t client \
    > ${DATA_temp}/${NOW}_openapi_initial_data.dump
echo -ne "*##########          * ( 50%)\r"

### Convert 'mydlink' data to 'UTF-8'
/usr/bin/iconv -f latin1 -t utf-8 ${DATA_temp}/${NOW}_initial_data.dump > ${DATA_temp}/${NOW}_initial_data-utf8.dump
echo -ne "*############        * ( 60%)\r"

### Remove unused file
rm -f ${DATA_temp}/${NOW}_initial_data.dump
cd /home/paul_tung/DBBackup
echo -ne "*##############      * ( 70%)\r"

#### Remove old backup files
#rm -f *_RDV2_init_data.tar.bz2
#rm -f ${RDFS_temp}/paul_tung/*_RDV2_init_data.tar.bz2
#echo -ne "*################### * ( 75%)\r"

### Make a tarball
/bin/tar -jcf ${NOW}_RDV2_init_data.tar.bz2 ${DATA_temp}/*
echo -ne "*##################  * ( 90%)\r"

### Copy new tarball to RD fileserver and clean up
/bin/cp -f ${NOW}_RDV2_init_data.tar.bz2 ${RDFS_temp}/paul_tung/
sudo umount ${RDFS_temp} && rm -fr ${RDFS_temp} && rm -fr ${DATA_temp}
echo -ne "*####################* (100%)\r"
echo -e "\n\e[1m\e[32mDone!\e[0m"



Step0: logon to database server
# ssh twrd@$env-$location-db-1.auto.mydlink.com

Step1: preparation (login as root)
# sudo su -
# mkdir -p /usr/local/pgsql/database
upload RD-V2 exported database file *.bz2 and db.sh to /usr/local/pgsql/database

# chmod 755 /usr/local/pgsql/database/*
# chown -R postgres /usr/local/pgsql
# chgrp -R postgres /usr/local/pgsql

Step2: initialize database
# sudo su - postgres
# rm -rf /usr/local/pgsql/data
# initdb -D /usr/local/pgsql/data
# postgres -D /usr/local/pgsql/data &
# psql -l
default database tables will display

Step3: run db.sh to import RD-V2 database
# cd /usr/local/pgsql/database
# ./db.sh

Step4: fix database listen port from localhost to *
# mco puppet -I runonce /$env-$location-db/
# mco puppet -I status /$env-$location-db/

Step5: change dynamic ddb config file (min-provisioned-reads and min-provisioned-writes set to 1)
copy ddb.sh to /mydlink/rd_tools/dynamic_dynamodb_monitor/ddb_config/$aws_region
# cd /mydlink/rd_tools/dynamic_dynamodb_monitor/ddb_config/$aws_region
# ./ddb.sh
