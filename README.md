
# Zabbix

Zabbix is an enterprise-class open source distributed monitoring solution for networks and applications.

## Sample pillars

### Sample pillar of Zabbix agent

    zabbix:
      agent:
        enabled: true
        server:
          host: 10.0.0.20
          port: ...

### Sample pillar of Zabbix server

    zabbix:
      server:
        enabled: true
        database:
          engine: mysql
          host: localhost
          user: ...
          password: ...

### Sample pillar with custom logging

    zabbix:
      server:
        enabled: true
        database:
          engine: mysql
          host: localhost
          user: ...
          password: ...
        logging: syslog

## Read more

* https://www.zabbix.com/documentation/2.0/manual/installation/install_from_packages
* https://github.com/pengyao/salt-zabbix/tree/master/salt/zabbix
* https://github.com/czhujer/puppet-zabbixagent