{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

{% set master_ip = salt['cmd.run']('salt-ssh {0} network.ipaddrs'.format(params.master_host)) %}
{% set host = salt['pillar.get']('host') %}
{% set minion_id = salt['pillar.get']('minion_id') %}

configure_master:
  cmd.run:
    - name: 'salt-ssh {{ host }} cmd.run "/usr/local/sbin/salt-config -i {{ minion_id }} -m {{ master_ip.split('-')[4] }}"'

restart_minion_service:
  cmd.run:
    - names:
      - 'salt-ssh {{ host }} cmd.run "launchctl stop com.saltstack.salt.minion"'
      - 'salt-ssh {{ host }} cmd.run "launchctl start com.saltstack.salt.minion"'
