
# Zabbix

Zabbix is an enterprise-class open source distributed monitoring solution for networks and applications.

## Sample pillars

### Sample pillar of Zabbix agent

    zabbix:
      agent:
        enabled: true

### Sample pillar of Zabbix server

    zabbix:
      server:
        enabled: true
        database:
          engine: mysql
          host: localhost
          user: ...
          password: ...

## Read more

* https://www.zabbix.com/documentation/2.0/manual/installation/install_from_packages
* https://github.com/pengyao/salt-zabbix/tree/master/salt/zabbix
* https://forge.puppetlabs.com/softek/zabbixagent