
include:
{% if pillar.zabbix.agent is defined %}
- zabbix.agent
{% endif %}
{% if pillar.zabbix.server is defined %}
- zabbix.server
{% endif %}
