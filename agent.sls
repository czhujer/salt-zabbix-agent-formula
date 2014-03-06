{% set agent = pillar.zabbix.agent %}

{%- if agent.enabled %}

{% set version = agent.get('version', '2') %}

{%- if grains.kernel == "Linux" %}

{%- if grains.os_family == "RedHat" %}

{% set zabbix_agent_config = '/etc/zabbix_agentd.conf' %}

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

zabbix_agent_firewall_rule:
  iptables.insert:
    - position: 4
    - table: filter
    - chain: INPUT
    - jump: ACCEPT
    - dport: 10050
    - proto: tcp
    - source: 10.0.110.36/32
    - save: True

{%- endif %}

{%- if grains.os_family == "Debian" %}

{% set zabbix_agent_config = '/etc/zabbix/zabbix_agentd.conf' %}

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

{%- endif %}

{%- if grains.kernel == "Windows" %}

{% set zabbix_confdir = 'C:/' %}
{% set zabbix_homedir = '%programfiles%/zabbix' %}

{% if version == '2' %}
{% set zabbix_agent_version = '2.0.10' %}
{% set zabbix_agent_source_hash = 'md5=3c18e6d659f15bf3970bea65d1e1dd22' %}
{% else %}
{% set zabbix_agent_version = '1.8.19' %}
{% set zabbix_agent_source_hash = 'md5=3eafd5287866898a4ce3701091178e2e' %}
{% endif %}

zabbix_agent_config:
  file.managed:
  - name: {{ zabbix_confdir }}zabbix_agentd.conf
  - source: salt://zabbix/conf/zabbix_agentd.win.conf
  - template: jinja

zabbix_agent_package_download:
  file.managed:
  - name: C:/zabbix_agents_{{ zabbix_agent_version }}.win.zip
  - source: http://www.zabbix.com/downloads/{{ zabbix_agent_version }}/zabbix_agents_{{ zabbix_agent_version }}.win.zip
  - source_hash: {{ zabbix_agent_source_hash }}

zabbix_agent_package_unpack:
  cmd.run:
  - names:
    - "'%programfiles%/7-Zip/7z.exe' x C:/zabbix_agents_{{ zabbix_agent_version }}.win.zip '{{ zabbix_homedir }}'"
  - unless: sc query "Zabbix Agent"
  - require:
    - file: zabbix_agent_package_download

zabbix_agent_service_install:
  cmd.run:
  - names:
    - "{{ zabbix_homedir }}/bin/zabbix_agentd.exe --install"
  - unless: sc query "Zabbix Agent"
  - require:
    - file: zabbix_agent_config
    - cmd: zabbix_agent_package_unpack

zabbix_agent_service:
  service.running:
  - name: zabbix-agent
  - enable: True
  - require:
    - cmd: zabbix_agent_service_install
  - watch:
    - file: zabbix_agent_config

{%- endif %}

{%- else %}

{%- if grains.kernel == "Linux" %}

zabbix_agent_packages:
  pkg.removed:
  - names:
    - zabbix20-agent
    - zabbix20
    - zabbix-agent
    - zabbix

{%- endif %}

{%- if grains.kernel == "Windows" %}

{# TODO - erase files, archives, erase windows services from ... etc #}

{%- endif %}

{%- endif %}
