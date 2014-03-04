{% set agent = pillar.zabbix.agent %}

{%- if agent.enabled %}

{% set version = agent.get('version', '2') %}

{%- if grains.os_family == "RedHat" %}

{% set zabbix_agent_config == '/etc/zabbix_agentd.conf' %}

{% if version == '2' %}
{% set zabbix_package_present = 'zabbix20-agent' %}
{% set zabbix_packages_absent = ['zabbix-agent', 'zabbix'] %}
{% else %}
{% set zabbix_package_present = 'zabbix-agent' %}
{% set zabbix_packages_absent = ['zabbix20-agent', 'zabbix20'] %}
{% endif %}

zabbix_agent_absent_packages:
  pkg.removed:
  - names: {{ zabbix_packages_absent }}

zabbix_agent_packages:
  pkg.installed:
  - name: {{ zabbix_package_present }}

{%- endif %}

{%- if grains.os_family == "Debian" %}

{% set zabbix_agent_config == '/etc/zabbix/zabbix_agentd.conf' %}


{% if version == '2' %}

zabbix_agent_repo:
  pkgrepo.managed:
  - human_name: Zabbix
  - names:
    - deb http://repo.zabbix.com/zabbix/2.0/ubuntu {{ grains.oscodename }} main
    - deb-src http://repo.zabbix.com/zabbix/2.0/ubuntu {{ grains.oscodename }} main
  - file: /etc/apt/sources.list.d/zabbix.list
  - key_url: salt://zabbix/conf/zabbix-apt.gpg

zabbix_agent_packages:
  pkg.installed:
  - names:
    - zabbix-agent
  - require:
    - pkgrepo: zabbix_agent_repo

{% else %}

zabbix_agent_packages:
  pkg.installed:
  - name: zabbix-agent

{% endif %}

{%- endif %}

zabbix_agent_config:
  file.managed:
  - name: {{ zabbix_agent_config }}
  - source: salt://zabbix/conf/zabbix_agentd.conf
  - template: jinja
  - require:
    - pkg: zabbix_agent_packages

zabbix_agentd.conf.d:
  file.directory:
  - name: /etc/zabbix/zabbix_agentd.conf.d
  - makedirs: true
  - require:
    - pkg: zabbix_agent_packages

zabbix_agent_service:
  service.running:
  - name: zabbix-agent
  - enable: True
  - watch:
    - file: zabbix_agent_config

{%- else %}

zabbix_agent_packages:
  pkg.removed:
  - names:
    - zabbix20-agent
    - zabbix20
    - zabbix-agent
    - zabbix

{%- endif %}