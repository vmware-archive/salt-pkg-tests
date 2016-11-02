{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

{% if params.on_smartos %}
{% set update_path = salt['environ.get']('PATH', '') + ':/opt/salt/bin/' %}
add_saltkey_path:
   environ.setenv:
     - name: PATH
     - value: {{ update_path }}
     - update_minion: True

disable_services:
  cmd.run:
    - names:
      - svcadm disable salt-minion
      - svcadm disable salt-master
{% else %}
disable_services:
  service.dead:
    - names:
      - salt-master
      - salt-minion
    - require_in:
      - file: remove_pki
      - file: clear_minion_id
      - file: minion_config
{% endif %}

remove_pki:
  file.absent:
    - name: {{ params.pki_config }}

clear_minion_id:
  file.absent:
    - name: {{ params.minion_id_config }}

minion_config:
  file.managed:
    - name: {{ params.minion_config }}
    - contents: |
        master: localhost
        id: {{ params.minion_id }}

enable_services:
# this doesn't seem to be working
#  service.enabled:
#    - names:
#      - salt-master
#      - salt-minion
  cmd.run:
    - names:
      - {{ params.service_master }}
      - {{ params.service_minion }}
    - require:
      - file: remove_pki
      - file: clear_minion_id
      - file: minion_config

wait_for_key:
  cmd.run:
    - name: sleep 30
    - require:
      - cmd: enable_services

accept_key:
  cmd.run:
    - name: 'salt-key -ya {{ params.minion_id }}'
    - require:
      - cmd: wait_for_key
