#!/bin/bash

# WAIT_DB_TIMER
# WAIT_CONTAINER_KEY

# set -x

set -e

echo Wait contaner key: ${WAIT_CONTAINER_KEY:=mysql-java-embulk-docker}
echo Redis host: ${REDIS_SERVER_HOST:=$REDIS_PORT_6379_TCP_ADDR}
echo Redis port: ${REDIS_SERVER_PORT:=$REDIS_PORT_6379_TCP_PORT}

function check_db {
    if [ "$MYSQL_ROOT_PASSWORD" ]; then
	mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "status"
    elif [ "$MYSQL_ALLOW_EMPTY_PASSWORD" ]; then
	mysql -e "status"
    else
	exit 1
    fi
}

function wait_db {
    result=1
    for i in $(seq 1 ${WAIT_DB_TIMER:-10})
    do
	sleep 1s
	result=0
	check_db && break
	result=1
    done
    if [ $result = 1 ]; then
	exit 1
    fi
}

if [ "${1:0:1}" = '-' ]; then
    set -- mysqld "$@"
fi

is_install=false

if [ "$1" = 'mysqld' ]; then
    # read DATADIR from the MySQL config
    DATADIR="$("$@" --verbose --help 2>/dev/null | awk '$1 == "datadir" { print $2; exit }')"

    if [ ! -d "$DATADIR/mysql" ]; then
        if [ -z "$MYSQL_ROOT_PASSWORD" -a -z "$MYSQL_ALLOW_EMPTY_PASSWORD" ]; then
            echo >&2 'error: database is uninitialized and MYSQL_ROOT_PASSWORD not set'
            echo >&2 '  Did you forget to add -e MYSQL_ROOT_PASSWORD=... ?'
            exit 1
        fi

	is_install=true

        echo 'Running mysql_install_db ...'
        mysql_install_db --datadir="$DATADIR"
        echo 'Finished mysql_install_db'

        # These statements _must_ be on individual lines, and _must_ end with
        # semicolons (no line breaks or comments are permitted).
        # TODO proper SQL escaping on ALL the things D:

        tempSqlFile='/tmp/mysql-first-time.sql'
        cat > "$tempSqlFile" <<-EOSQL
            DELETE FROM mysql.user ;
            CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
            GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
            DROP DATABASE IF EXISTS test ;
EOSQL

        if [ "$MYSQL_DATABASE" ]; then
            echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;" >> "$tempSqlFile"
        fi

        if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
            echo "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' ;" >> "$tempSqlFile"

            if [ "$MYSQL_DATABASE" ]; then
                echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%' ;" >> "$tempSqlFile"
            fi
        fi

        echo 'FLUSH PRIVILEGES ;' >> "$tempSqlFile"

	# http://qiita.com/toritori0318/items/242274d4f5794e2f68e5
        # setup
        echo "use $MYSQL_DATABASE;" >> "$tempSqlFile"
	if [ -e "/opt/setup.d/setup.sql"]; then
            cat /opt/setup.d/setup.sql >> "$tempSqlFile"
	fi
        # start mysql
        set -- "$@" --init-file="$tempSqlFile"
    fi

    chown -R mysql:mysql "$DATADIR"
fi

exec "$@" &

wait_db

if [ -e "/opt/setup.d/setup.yml" ]; then
    if [ $is_install=true ]; then
	echo "embulk run setup.yml"
	cd /opt/setup.d && /opt/embulk run setup.yml
    fi
fi

if [ -n "$REDIS_SERVER_HOST" ]; then
    redis-cli -h $REDIS_SERVER_HOST -p $REDIS_SERVER_PORT SET $WAIT_CONTAINER_KEY up
fi

sleep infinity
