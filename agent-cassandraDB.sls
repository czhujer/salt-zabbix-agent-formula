
zabbix_agent_cassandra_config:
  file.managed:
  - name: /etc/zabbix/zabbix_agentd.conf.d/zabbix-cassandraDB.conf
  - source: salt://zabbix/conf/zabbix-cassandraDB.conf
  - user: root
  - group: root
  - mode: 644
  - require:
    - file: zabbix_agentd.conf.d

zabbix_agent_cassandra_script1:
  file.managed:
  - name: /root/scripts/cassandra.pl
  - source: salt://zabbix/scripts/cassandra.pl
  - user: root
  - group: root
  - mode: 755
  - require:
    - file: zabbix_agent_root_scripts

zabbix_agent_cassandra_script2:
  file.managed:
  - name: /root/scripts/check_cassandra_nodes.pl
  - source: salt://zabbix/scripts/check_cassandra_nodes.pl
  - user: root
  - group: root
  - mode: 755
  - require:
    - file: zabbix_agent_root_scripts

zabbix_agent_cassandra_script3:
  file.managed:
  - name: /root/scripts/check_cassandra_tpstats.pl
  - source: salt://zabbix/scripts/check_cassandra_tpstats.pl
  - user: root
  - group: root
  - mode: 755
  - require:
    - file: zabbix_agent_root_scripts

zabbix_agent_cassandra_m1:
  file.managed:
  - name: /usr/share/perl5/HariSekhonUtils.pm
  - source: salt://zabbix/scripts/HariSekhonUtils.pm
  - user: root
  - group: root
  - mode: 644
  - require:
    - file: zabbix_agent_root_scripts

zabbix_agent_packages2:
  pkg.installed:
  - names:
    - perl-JSON
  - require:
    - file: zabbix_agent_cassandra_m1

zabbix_agent_cassandra_d1:
  file.directory:
    - name: /usr/share/perl5/HariSekhon/Cassandra
    - makedirs: true
    - require:
      - file: zabbix_agent_root_scripts

zabbix_agent_cassandra_m3:
  file.managed:
  - name: /usr/share/perl5/HariSekhon/Cassandra/Nodetool.pm
  - source: salt://zabbix/scripts/Nodetool.pm
  - user: root
  - group: root
  - mode: 644
  - require:
    - file: zabbix_agent_cassandra_d1

zabbix_agent_cassandra_m4:
  file.managed:
  - name: /usr/share/perl5/HariSekhon/Cassandra.pm
  - source: salt://zabbix/scripts/Cassandra.pm
  - user: root
  - group: root
  - mode: 644
  - require:
     - file: zabbix_agent_root_scripts
