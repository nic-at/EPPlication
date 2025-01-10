#!/usr/bin/env bash

{
set -e

PROJECT=/home/epplication/EPPlication

if [ ! -d "$PROJECT/local/lib/perl5" ]; then
    echo "install perl dependencies"
    su -c "cd $PROJECT && carton install --deployment && rm -rf ~/.cpanm" epplication
fi

if [ ! -f "/etc/nginx/sites-available/epplication" ]; then
    echo "nginx: enable epplication"
    cp $PROJECT/nginx.conf /etc/nginx/sites-available/epplication
    ln -s /etc/nginx/sites-available/epplication /etc/nginx/sites-enabled/epplication
fi

if [ ! -f "/etc/init.d/epplication_fcgi" ]; then
    echo "install epplication_fcgi initd file"
    perl script/epplication_fcgi.initd get_init_file > /etc/init.d/epplication_fcgi
    chmod u+x /etc/init.d/epplication_fcgi
    update-rc.d epplication_fcgi defaults /etc/init.d/epplication_fcgi start
fi
if [ ! -f "/etc/init.d/epplication_taskrunner" ]; then
    echo "install epplication_taskrunner initd file"
    perl script/epplication_taskrunner.initd get_init_file > /etc/init.d/epplication_taskrunner
    chmod u+x /etc/init.d/epplication_taskrunner
    update-rc.d epplication_taskrunner defaults
fi

if [ ! -d "/var/log/epplication" ]; then
    echo "create /var/log/epplication"
    mkdir /var/log/epplication
    touch /var/log/epplication/main.log
    chown -R epplication:epplication /var/log/epplication
fi
if [ ! -d "/var/run/epplication" ]; then
    echo "/var/run/create epplication"
    mkdir /var/run/epplication
    chown epplication:epplication /var/run/epplication
fi

if [ ! -f "$PROJECT/epplication_web_local.pl" ]; then
    echo "create epplication config file (local)"
    carton exec $PROJECT/script/epplication_config_helper.pl \
       --user epplication \
       --group epplication \
       --perl "/usr/bin/perl -I$PROJECT/local/lib/perl5 -I$PROJECT/lib" \
       --db-host epplication-db \
       --db-port 5432 \
       --db-name epplication \
       --db-user epplication \
       --db-password epplication \
       > $PROJECT/epplication_web_local.pl
fi
if [ ! -f "$PROJECT/epplication_web_testing.pl" ]; then
    echo "create epplication config file (testing)"
    carton exec $PROJECT/script/epplication_config_helper.pl \
       --user epplication \
       --group epplication \
       --perl "/usr/bin/perl -I$PROJECT/local/lib/perl5 -I$PROJECT/lib" \
       --db-host epplication-db \
       --db-port 5432 \
       --db-name epplication_testing \
       --db-user epplication \
       --db-password epplication \
       > $PROJECT/epplication_web_testing.pl
fi

if [ -f "/etc/nginx/sites-enabled/default" ]; then
    echo "remove default nginx site"
    rm /etc/nginx/sites-enabled/default
fi

until su -c "PGPASSWORD=epplication psql -h epplication-db -U epplication -c '\q'" epplication; do
    echo "Postgres is unavailable - sleeping"
    sleep 1
done

echo "Postgres is up - check version"

set +e
db_version=`su -c "carton exec $PROJECT/script/database.pl --cmd database-version 2>&1" epplication`
set -e

if [[ $db_version = *'relation "dbix_class_deploymenthandler_versions" does not exist'* ]]; then
    echo "init epplication DB"
    su -c "carton exec $PROJECT/script/database.pl --cmd install" epplication
    su -c "carton exec $PROJECT/script/database.pl --cmd init --create-default-branch --create-default-roles --create-default-tags" epplication
    su -c "carton exec $PROJECT/script/database.pl --cmd adduser --username admin --password admin123 --add-all-roles" epplication
else
    echo "check for epplication DB upgrade"
    set +e
    db_version=`su -c "carton exec $PROJECT/script/database.pl --cmd database-version 2>&1" epplication`
    schema_version=`su -c "carton exec $PROJECT/script/database.pl --cmd schema-version 2>&1" epplication`
    set -e
    echo "db_version: $db_version"
    echo "schema_version: $schema_version"
    if (( $db_version < $schema_version )); then
        echo "update DB"
        su -c "carton exec $PROJECT/script/database.pl --cmd upgrade 2>&1" epplication
    fi
fi

if [ ! -f "$PROJECT/ssh_keys/id_ed25519" ]; then
    echo "ssh-keygen"
    su -c "ssh-keygen -t ed25519 -C 'container@epplication.test' -f $PROJECT/ssh_keys/id_ed25519 -N ''" epplication
fi

if [ ! -d "/home/epplication/.ssh" ]; then
    echo "allow epplication ssh key access for localhost"
    su -c "mkdir -m 700 ~/.ssh" epplication
    su -c "cat $PROJECT/ssh_keys/id_ed25519.pub >> ~/.ssh/authorized_keys" epplication
    su -c "chmod 600 ~/.ssh/authorized_keys" epplication
    /etc/init.d/ssh restart # without restart ssh-keyscan returns no output
    su -c "ssh-keyscan -H epplication-app >> ~/.ssh/known_hosts" epplication
fi

echo "container setup complete"

/etc/init.d/ssh restart
/etc/init.d/nginx restart
/etc/init.d/epplication_fcgi restart
/etc/init.d/epplication_taskrunner restart
tail -f /var/log/epplication/main.log

} >&2 # redirect stdout to stderr
