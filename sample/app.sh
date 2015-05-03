#! /bin/bash

# set -x

set -e

echo WAIT_CONTAINER_KEY: ${WAIT_CONTAINER_KEY:="mysql-java-embulk-docker"}
echo MySQL host: ${MYSQL_SERVER_HOST:=$MYSQL_PORT_3306_TCP_ADDR}
echo MySQL port: ${MYSQL_SERVER_PORT:=$MYSQL_PORT_3306_TCP_PORT}
echo PostgreSQL host: ${POSTGRESQL_SERVER_HOST:=$POSTGRESQL_PORT_5432_TCP_ADDR}
echo PostgreSQL port: ${POSTGRESQL_SERVER_PORT:=$POSTGRESQL_PORT_5432_TCP_PORT}
echo Redis host: ${REDIS_SERVER_HOST:=$REDIS_PORT_6379_TCP_ADDR}
echo Redis port: ${REDIS_SERVER_PORT:=$REDIS_PORT_6379_TCP_PORT}
export MYSQL_SERVER_HOST
export MYSQL_SERVER_PORT
export POSTGRESQL_SERVER_HOST
export POSTGRESQL_SERVER_PORT
export REDIS_SERVER_HOST
export REDIS_SERVER_PORT

function wait_container_redis {
    result=1
    for i in $(seq 1 ${WAIT_CONTAINER_TIMER:-100})
    do
	sleep 1s
	result=0
	if [ $(redis-cli -h $REDIS_SERVER_HOST -p $REDIS_SERVER_PORT GET $WAIT_CONTAINER_KEY)'' = "up" ]; then
	    break
	fi
	echo spark-sql-scala-docker wait: $REDIS_SERVER_HOST
	result=1
    done
    if [ $result = 1 ]; then
	exit 1
    fi
}

wait_container_redis

mysql -u $MYSQL_SERVER_USER -p$MYSQL_SERVER_PASSWORD --host=$MYSQL_SERVER_HOST --port=$MYSQL_SERVER_PORT -e "select count(*) from baseball.batting"
