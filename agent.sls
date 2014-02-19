{% set agent = pillar.zabbix.agent %}

{%- if agent.enabled %}

{% set version = agent.get('version', '2') %}

{%- if grains.os_family == "RedHat" %}

{% if version == '2' %}
{% set zabbix_package_present = 'zabbix20-agent' %}
{% set zabbix_packages_absent = ['zabbix-agent', 'zabbix'] %}
{% else %}
{% set zabbix_package_present = 'zabbix-agent' %}
{% set zabbix_packages_absent = ['zabbix20-agent', 'zabbix20'] %}
{% endif %}

zabbix_agent_absent_packages:
  pkg.absent:
  - names: zabbix_packages_absent

zabbix_agent_packages:
  pkg.installed:
  - name: {{ zabbix_package_present }}
  - require:
    - pkg: zabbix_agent_absent_packages

{%- endif %}

{%- if grains.os_family == "Debian" %}

{% if version == '2' %}

{% set zabbix_base_url = 'http://repo.zabbix.com/zabbix/2.0/ubuntu/pool/main/z/zabbix-release' %}
{% set zabbix_base_file = 'zabbix-release_2.0-1precise_all.deb' %}

zabbix_package_download:
  cmd.run:
  - name: wget {{ zabbix_base_url }}/{{ zabbix_base_file }}
  - unless: "[ -f /root/{{ zabbix_base_file }} ]"
  - cwd: /root

zabbix_agent_packages:
  pkg.installed:
  - sources:
    - vagrant: /root/{{ zabbix_base_file }}
  - require:
    - cmd: zabbix_download_package

{% else %}

zabbix_agent_packages:
  pkg.installed:
  - name: zabbix-agent

{% endif %}

{%- endif %}

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
    - zabbix20
    - zabbix-agent
    - zabbix

{%- endif %}