{% set salt_version = pillar.get('salt_version', '') %}
{% set minion_id = '{0}-{1}'.format(grains.get('id'), salt_version) %}


disable_services:
  service.dead:
    - names:
      - salt-master
      - salt-minion
    - require_in:
      - file: remove_pki
      - file: clear_minion_id
      - file: minion_config

remove_pki:
  file.absent:
    - name: /etc/salt/pki

clear_minion_id:
  file.absent:
    - name: /etc/salt/minion_id

minion_config:
  file.managed:
    - name: /etc/salt/minion
    - contents: |
        master: localhost
        id: {{ minion_id }}

enable_services:
# this doesn't seem to be working
#  service.enabled:
#    - names:
#      - salt-master
#      - salt-minion
  cmd.run:
    - names:
      - service salt-master start
      - service salt-minion start
    - require:
      - file: remove_pki
      - file: clear_minion_id
      - file: minion_config

wait_for_key:
  cmd.run:
    - name: sleep 7
    - require:
      - cmd: enable_services

accept_key:
  cmd.run:
    - name: 'echo y | salt-key -a {{ minion_id }}'
    - require:
      - cmd: wait_for_key
