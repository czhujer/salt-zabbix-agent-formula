{%- if pillar.zabbix.agent.enabled %}

zabbix_agent_packages:
  pkg.installed:
  - names:
    - zabbix20-agent

zabbix_agent_config:
  file.managed:
  - name: /etc/zabbix_agentd.conf
  - source: salt://zabbix/files/etc/zabbix_agentd.conf
  - template: jinja
  - require:
    - pkg: zabbix_agent_packages

zabbix_agent_service:
  service.running:
  - name: zabbix-agent
  - enable: True
  - watch:
    - file: zabbix_agent_config

zabbix_agentd.conf.d:
  file.directory:
  - name: /etc/zabbix/zabbix_agentd.conf.d
  - require:
    - service: zabbix-agent

{%- else %}

zabbix_agent_packages:
  pkg.absent:
  - names:
    - zabbix20-agent

{%- endif %}