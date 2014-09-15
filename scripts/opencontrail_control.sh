#!/bin/bash

part_cassandradb() {

    service supervisord-contrail-database $action

    supervisorctl -s http://localhost:9007 $action

}

part_redis(){
:
#    service redis $action

#    service redis-query $action

#    service redis-uve $action

#    service redis-webui $action

}

part_oc() {

    service supervisor-analytics $action

    /usr/bin/supervisorctl -s http://localhost:9002 $action

    service supervisor-config $action

    /usr/bin/supervisorctl -s http://localhost:9004 $action

    service supervisor-control $action

    /usr/bin/supervisorctl -s http://localhost:9003 $action

    service supervisor-webui $action

    /usr/bin/supervisorctl -s http://localhost:9008 $action

    #/etc/init.d/contrail-svc-monitor
    supervisorctl -s http://localhost:9004 status

}

part_rabbitmq() {

   if [ $action == "status" ]; then
        rabbitmqctl cluster_status
   else
    service rabbitmq-server $action
   fi

}

part_others() {

    service zookeeper $action

    service neutron-server $action

    service libvirtd $action

    service haproxy $action

}


usage() {

    echo "usage:  `basename $0` (cassandra,redis,oc,rabbitmq,others,all) (start|stop|restart|status)"

}

#validation input var
case $2 in

start)
    action=start
;;
stop)
    action=stop
;;
restart)
    action=restart
;;
status)
    action=status
;;
*)
    usage
    exit;
;;
esac

case $1 in

cassandra)
    part_cassandradb
;;
rabbitmq)
    part_rabbitmq
;;
redis)
    part_redis
;;
oc)
    part_oc
;;
others)
    part_others
;;
all)
    part_rabbitmq
    part_cassandradb
    part_redis
    part_oc
    part_others
;;
esac


