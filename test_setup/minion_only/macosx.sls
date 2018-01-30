{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

configure_master:
  cmd.run:
    - name: /usr/local/sbin/salt-config -i {{ params.minion_id }} -m {{ params.master_host }}

restart_minion_service:
  cmd.run:
    - names:
      - launchctl stop com.saltstack.salt.minion
      - launchctl start com.saltstack.salt.minion
