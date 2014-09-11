
zabbix_agent_redis_config:
  file.managed:
  - name: /etc/zabbix/zabbix_agentd.conf.d/zabbix-redis.conf
  - source: salt://zabbix/conf/zabbix-redis.conf
  - user: root
  - group: root
  - mode: 644
  - require:
    - file: zabbix_agentd.conf.d

zabbix_agent_redis_script:
  file.managed:
  - name: /root/scripts/zbx_redis_stats.py
  - source: salt://zabbix/scripts/zbx_redis_stats.py
  - user: root
  - group: root
  - mode: 755
  - require:
    - file: zabbix_agent_root_scripts

