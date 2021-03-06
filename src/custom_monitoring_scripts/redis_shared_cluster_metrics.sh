#!/usr/bin/env bash

REDIS_INSTANCES_PATH="/var/vcap/store/cf-redis-broker/redis-data"
REDIS_INSTANCES=$(for i in $(ls -d ${REDIS_INSTANCES_PATH}/*); do echo $i | awk -F/ '{print $7}'; done)
REDIS_BIN='/var/vcap/packages/redis/bin/redis-cli'
REDIS_CREDENTIALS=''


###Retrieve REDIS credentials
declare -A REDIS_CREDENTIALS
i=0
for REDIS_INSTANCE in $REDIS_INSTANCES
do
    REDIS_CREDENTIALS[$i,instance_id]=$REDIS_INSTANCE
    REDIS_CREDENTIALS[$i,instance_port]=$(grep port $REDIS_INSTANCES_PATH/$REDIS_INSTANCE/redis.conf |  awk '{print $2}')
    REDIS_CREDENTIALS[$i,instance_password]=$(grep requirepass $REDIS_INSTANCES_PATH/$REDIS_INSTANCE/redis.conf | awk '{print $2}')
    i=$(($i+1))
done

function list_instances {
    for (( j=0;j<$i;j++ ))
    do
    instance_id=${REDIS_CREDENTIALS[$j,instance_id]}
    instance_port=${REDIS_CREDENTIALS[$j,instance_port]}
    printf "%s %s 0\n" $instance_id $instance_port
    done
}

function count_connected_clients {
    for (( j=0;j<$i;j++ ))
    do
    instance_id=${REDIS_CREDENTIALS[$j,instance_id]}
    instance_port=${REDIS_CREDENTIALS[$j,instance_port]}
    instance_password=${REDIS_CREDENTIALS[$j,instance_password]}
    QUERY=$($REDIS_BIN -p $instance_port -a $instance_password CLIENT LIST | wc -l)
    printf "%s %s %s\n" $instance_id $instance_port $QUERY
    done
}

function database_keys_count {
    for (( j=0;j<$i;j++ ))
    do
    instance_id=${REDIS_CREDENTIALS[$j,instance_id]}
    instance_port=${REDIS_CREDENTIALS[$j,instance_port]}
    instance_password=${REDIS_CREDENTIALS[$j,instance_password]}
    QUERY=$($REDIS_BIN -p $instance_port -a $instance_password DBSIZE)
    printf "%s %s %s\n" $instance_id $instance_port $QUERY
    done
}

function get_used_memory {
    for (( j=0;j<$i;j++ ))
    do
    instance_id=${REDIS_CREDENTIALS[$j,instance_id]}
    instance_port=${REDIS_CREDENTIALS[$j,instance_port]}
    instance_password=${REDIS_CREDENTIALS[$j,instance_password]}
    QUERY=$($REDIS_BIN -p $instance_port -a $instance_password INFO | grep 'used_memory:' | awk -F: '{print $2}')
    printf "%s %s %s\n" $instance_id $instance_port $QUERY
    done
}

function get_maxmemory {
    for (( j=0;j<$i;j++ ))
    do
    instance_id=${REDIS_CREDENTIALS[$j,instance_id]}
    instance_port=${REDIS_CREDENTIALS[$j,instance_port]}
    instance_password=${REDIS_CREDENTIALS[$j,instance_password]}
    QUERY=$($REDIS_BIN -p $instance_port -a $instance_password INFO | grep 'maxmemory:' | awk -F: '{print $2}')
    printf "%s %s %s\n" $instance_id $instance_port $QUERY
    done
}

function get_evicted_keys {
    for (( j=0;j<$i;j++ ))
    do
    instance_id=${REDIS_CREDENTIALS[$j,instance_id]}
    instance_port=${REDIS_CREDENTIALS[$j,instance_port]}
    instance_password=${REDIS_CREDENTIALS[$j,instance_password]}
    QUERY=$($REDIS_BIN -p $instance_port -a $instance_password INFO | grep 'evicted_keys:' | awk -F: '{print $2}')
    printf "%s %s %s\n" $instance_id $instance_port $QUERY
    done
}

function instance_health {
    for (( j=0;j<$i;j++ ))
    do
    instance_id=${REDIS_CREDENTIALS[$j,instance_id]}
    instance_port=${REDIS_CREDENTIALS[$j,instance_port]}
    instance_password=${REDIS_CREDENTIALS[$j,instance_password]}
    check_SET=$($REDIS_BIN -p $instance_port -a $instance_password SET instance_health "smooth")
    check_GET=$($REDIS_BIN -p $instance_port -a $instance_password GET instance_health)
    check_DEL=$($REDIS_BIN -p $instance_port -a $instance_password DEL instance_health)
    check_deleted=$($REDIS_BIN -p $instance_port -a $instance_password GET instance_health)
    if [ "$check_SET" == "OK" ] && [ "$check_GET" == "smooth" ] && [ "$check_DEL" == "1" ] && [ -z "$check_deleted" ]
    then QUERY=1
    else QUERY=0
    fi
    printf "%s %s %s\n" $instance_id $instance_port $QUERY
    done
}

function get_no_ttl_keys {
for (( j=0;j<$i;j++ ))
    do
    instance_id=${REDIS_CREDENTIALS[$j,instance_id]}
    instance_port=${REDIS_CREDENTIALS[$j,instance_port]}
    instance_password=${REDIS_CREDENTIALS[$j,instance_password]}
    no_ttl_keys=0
    $REDIS_BIN -p $instance_port -a $instance_password keys  "*" | while read LINE
        do TTL=`$REDIS_BIN -p $instance_port -a $instance_password ttl "$LINE"`
            if [ $TTL -eq  -1 ]
            then ((no_ttl_keys++))
            fi
        done
        printf "%s %s %s\n" $instance_id $instance_port $no_ttl_keys
done
}

$1
