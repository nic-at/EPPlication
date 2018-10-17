#!/bin/sh
# wait-for-postgres.sh

{

set -e

until su -c "PGPASSWORD=epplication psql -h db -U epplication -c '\q'" epplication; do
  echo "Postgres is unavailable - sleeping"
  sleep 1
done

echo "Postgres is up - check version"

set +e
db_version=`su -c "carton exec ./script/database.pl --cmd database-version 2>&1" epplication`
set -e

if [[ $db_version = *'relation "dbix_class_deploymenthandler_versions" does not exist'* ]]; then
  echo 'init epplication DB'
  su -c 'carton exec script/database.pl --cmd install'
  su -c 'carton exec script/database.pl --cmd init --create-default-branch --create-default-roles --create-default-tags'
  su -c 'carton exec script/database.pl --cmd adduser --username admin --password admin123 --add-all-roles'
fi

if [ ! -f /home/epplication/EPPlication/ssh_keys/id_rsa ]; then
  echo 'ssh-keygen'
  su -c 'ssh-keygen -b 2048 -t rsa -f /home/epplication/EPPlication/ssh_keys/id_rsa -q -N ""' epplication
fi

if [ ! -d /home/epplication/.ssh ]; then
  echo 'allow epplication ssh key'
  su -c 'mkdir -m 700 /home/epplication/.ssh' epplication
  su -c 'bash -c "cat /home/epplication/EPPlication/ssh_keys/id_rsa.pub >> /home/epplication/.ssh/authorized_keys"'
fi

/etc/init.d/ssh restart \
    && /etc/init.d/nginx restart \
    && /etc/init.d/epplication_fcgi restart \
    && /etc/init.d/epplication_taskrunner restart \
    && tail -f /var/log/epplication/main.log

} >&2 # redirect stout to stderr
