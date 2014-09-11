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

{#
zabbix_agent_firewall_rule:
  iptables.insert:
    - position: 4
    - table: filter
    - chain: INPUT
    - jump: ACCEPT
    - match: state
    - connstate: NEW
    - dport: 10050
    - proto: tcp
    - sport: 1025:65535
    - save: True
#}

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

{%- if ((pillar.get('nova', {}) is defined) or (pillar.get('neutron', {}).server is defined)) %}

zabbix_agent_config_openstack:
  file.managed:
  - name: /etc/zabbix/zabbix_agentd.conf.d/zabbix-openstack.conf
  - source: salt://zabbix/conf/zabbix-openstack.conf
  - template: jinja
  - require:
    - file: zabbix_agentd.conf.d

{%- endif %}

{%- if ((pillar.get('mysql', {}).cluster is defined) or (pillar.get('pacemaker', {}).cluster is defined)) %}

zabbix_agent_config_openstack_ha:
  file.managed:
  - name: /etc/zabbix/zabbix_agentd.conf.d/zabbix-ops-high-avail.conf
  - source: salt://zabbix/conf/zabbix-ops-high-avail.conf
  - template: jinja
  - require:
    - file: zabbix_agentd.conf.d

{%- if (pillar.get('sensu', {}).client is not defined) %}

zabbix_agent_folder_checks:
  file.directory:
  - name: /srv/sensu/checks
  - makedirs: true

zabbix_agent_check_galera_cluster:
  file.managed:
  - name: /srv/sensu/checks/check_galera_cluster
  - source: salt://zabbix/scripts/check_galera_cluster
  - mode: 755
  - require:
    - file: zabbix_agent_folder_checks

zabbix_agent_check_pacemaker:
  file.managed:
  - name: /srv/sensu/checks/check_pacemaker_actions
  - source: salt://zabbix/scripts/check_pacemaker_actions
  - mode: 755
  - require:
    - file: zabbix_agent_folder_checks

{%- endif %}

{%- endif %}

{%- if ((pillar.get('keystone', {}) is defined) or (pillar.get('glance', {}) is defined) or (pillar.get('neutron', {}).server is defined) or (pillar.get('pacemaker', {}).cluster is defined) or (pillar.opencontrail.database.get('enabled', "false") == true)) %}

zabbix_agent_sudoers_file:
  file.managed:
  - name: /etc/sudoers.d/zabbix-agent
  - source: salt://zabbix/conf/sudoer
  - template: jinja
  - user: root
  - group: root
  - mode: 440
  - defaults:
    user_name: zabbix

{%- endif %}

{%- if ((pillar.get('pacemaker', {}).cluster is defined) or (pillar.get('opencontrail', {}).database.enabled == true)) %}

zabbix_agent_root_scripts:
  file.directory:
  - name: /root/scripts
  - makedirs: true

{%- endif %}

{%- if (pillar.get('pacemaker', {}).cluster is defined) %}

zabbix_agent_crm_mon_stats:
  file.managed:
  - name: /root/scripts/crm_mon_stats.sh
  - source: salt://zabbix/scripts/crm_mon_stats.sh
  - template: jinja
  - user: root
  - group: root
  - mode: 755
  - require:
    - file: zabbix_agent_root_scripts

{%- endif %}

{#
# Contrail CassandraDB include
#}

{%- if (pillar.get('opencontrail', {}).database.enabled == true) %}
include:
- zabbix.agent-cassandraDB
{%- endif %}

{#
# Contrail redis include
#}

{%- if (pillar.get('opencontrail', {}).web.cache.engine == redis) %}
include:
- zabbix.agent-redis
{%- endif %}

zabbix_agent_service:
  service.running:
  - name: zabbix-agent
  - enable: True
  - watch:
    - file: zabbix_agent_config
{%- if ((pillar.get('nova', {}) is defined) or (pillar.get('neutron', {}).server is defined)) %}
    - file: zabbix_agent_config_openstack
{%- endif %}
{%- if ((pillar.get('mysql', {}).cluster is defined) or (pillar.get('pacemaker', {}).cluster is defined)) %}
    - file: zabbix_agent_config_openstack_ha
{%- endif %}
{%- if ((pillar.get('keystone', {}) is defined) or (pillar.get('glance', {}) is defined) or (pillar.get('neutron', {}).server is defined) or (pillar.get('pacemaker', {}).cluster is defined)) %}
    - file: zabbix_agent_sudoers_file
{%- endif %}
{%- if (pillar.opencontrail.database.get('enabled', "false") == true) %}
    - file: zabbix_agent_cassandra_config
    - file: zabbix_agent_cassandra_script1
    - file: zabbix_agent_cassandra_script2
    - file: zabbix_agent_cassandra_script3
    - file: zabbix_agent_cassandra_m1
    - file: zabbix_agent_cassandra_m3
    - file: zabbix_agent_cassandra_m4
{%- endif %}

{%- endif %}

{%- if grains.kernel == "Windows" %}

{% set zabbix_homedir = 'C:\zabbix-agent' %}
{% set zabbix_homedir2 = 'C:\zabbix-agent' %}

{% set zabbix_confdir = 'C:\zabbix-agent\conf' %}
{% set zabbix_confdir2 = 'C:\zabbix-agent\conf' %}

{% if version == '2' %}
{% set zabbix_agent_version = '2.0.10' %}
{% set zabbix_agent_source_hash = 'md5=3c18e6d659f15bf3970bea65d1e1dd22' %}
{% else %}
{% set zabbix_agent_version = '1.8.19' %}
{% set zabbix_agent_source_hash = 'md5=3eafd5287866898a4ce3701091178e2e' %}
{% endif %}

zabbix_agent_package_download:
  file.managed:
  - name: C:/zabbix_agents_{{ zabbix_agent_version }}.win.zip
  - source: http://www.zabbix.com/downloads/{{ zabbix_agent_version }}/zabbix_agents_{{ zabbix_agent_version }}.win.zip
  - source_hash: {{ zabbix_agent_source_hash }}

zabbix_agent_homedir:
  file.directory:
  - name: {{ zabbix_homedir }}

zabbix_agent_confdir:
  file.directory:
  - name: {{ zabbix_confdir }}
  - require:
    - file: zabbix_agent_homedir

zabbix_agent_package_unpack:
  cmd.run:
  - names:
    - C:\"Program files"\7-Zip\7z.exe -y x C:\zabbix_agents_{{ zabbix_agent_version }}.win.zip -o{{ zabbix_homedir2 }}
  - unless: sc query "Zabbix Agent"
  - timeout: 10
  - require:
    - file: zabbix_agent_confdir
    - file: zabbix_agent_homedir

zabbix_agent_config:
  file.managed:
  - name: {{ zabbix_confdir }}/zabbix_agentd.win.conf
  - source: salt://zabbix/conf/zabbix_agentd.win.conf
  - template: jinja
  - require:
    - file: zabbix_agent_package_download

{% if pillar.zabbix.agent.get("win_adv_items", "false") == true %}

zabbix_agent_win_adv_items_f1:
  file.managed:
  - name: {{ zabbix_homedir }}\zabbix_boot_time.vbs
  - source: salt://zabbix/conf/zabbix_boot_time.vbs
  - require:
    - file: zabbix_agent_homedir

zabbix_agent_win_adv_items_f2:
  file.managed:
  - name: {{ zabbix_homedir }}\zabbix_server_dns_config.vbs
  - source: salt://zabbix/conf/zabbix_server_dns_config.vbs
  - require:
    - file: zabbix_agent_homedir

zabbix_agent_win_adv_items_f3:
  file.managed:
  - name: {{ zabbix_homedir }}\zabbix_server_role.vbs
  - source: salt://zabbix/conf/zabbix_server_role.vbs
  - require:
    - file: zabbix_agent_win_adv_items_f2

zabbix_agent_win_adv_items_f4:
  file.managed:
  - name: {{ zabbix_homedir }}\zabbix_server_serialnumber.vbs
  - source: salt://zabbix/conf/zabbix_server_serialnumber.vbs
  - require:
    - file: zabbix_agent_win_adv_items_f3

zabbix_agent_win_adv_items_f5:
  file.managed:
  - name: {{ zabbix_homedir }}\zabbix_user_domain.vbs
  - source: salt://zabbix/conf/zabbix_user_domain.vbs
  - require:
    - file: zabbix_agent_win_adv_items_f4

zabbix_agent_win_adv_items_f6:
  file.managed:
  - name: {{ zabbix_homedir }}\zabbix_win_quota.vbs
  - source: salt://zabbix/conf/zabbix_win_quota.vbs
  - require:
    - file: zabbix_agent_win_adv_items_f5

zabbix_agent_win_adv_items_f7:
  file.managed:
  - name: {{ zabbix_homedir }}\zabbix_win_system_discovery.vbs
  - source: salt://zabbix/conf/zabbix_win_system_discovery.vbs
  - require:
    - file: zabbix_agent_win_adv_items_f6

zabbix_agent_win_adv_items_f8:
  file.managed:
  - name: {{ zabbix_homedir }}\zabbix_wus_update_all.vbs
  - source: salt://zabbix/conf/zabbix_wus_update_all.vbs
  - require:
    - file: zabbix_agent_win_adv_items_f7

zabbix_agent_win_adv_items_f9:
  file.managed:
  - name: {{ zabbix_homedir }}\zabbix_wus_update_crit.vbs
  - source: salt://zabbix/conf/zabbix_wus_update_crit.vbs
  - require:
    - file: zabbix_agent_win_adv_items_f8

{% endif %}

zabbix_agent_service_install:
  cmd.run:
  - names:
    - {{ zabbix_homedir2 }}\bin\win64\zabbix_agentd.exe --install --config {{ zabbix_confdir }}\zabbix_agentd.win.conf"
  - unless: sc query "Zabbix Agent"
  - require:
    - file: zabbix_agent_config
    - cmd: zabbix_agent_package_unpack
{% if pillar.zabbix.agent.get("win_adv_items", "false") == true %}
    - file: zabbix_agent_win_adv_items_f9
{% endif %}

zabbix_agent_win_firewall:
  cmd.run:
  - names:
    - netsh advfirewall firewall add rule name="zabbix-agent" protocol=TCP localport=10050 action=allow dir=IN remoteip=10.0.110.36
  - unless: netsh advfirewall firewall show rule name="zabbix-agent"
  - require:
    - cmd: zabbix_agent_service_install

zabbix_agent_service:
  service.running:
  - name: Zabbix Agent
  - enable: True
  - require:
    - cmd: zabbix_agent_service_install
  - watch:
    - file: zabbix_agent_config
{% if pillar.zabbix.agent.get("win_adv_items", "false") == true %}
    - file: zabbix_agent_win_adv_items_f9
{% endif %}

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
