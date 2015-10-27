{% set salt_version = pillar.get('salt_version', '') %}
{% set minion_id = '{0}-{1}'.format(grains.get('id'), salt_version) %}

{% set utils = ['salt', 'salt-api', 'salt-call', 'salt-cloud', 'salt-cp', 'salt-key', 'salt-master', 'salt-minion', 'salt-proxy', 'salt-run', 'salt-ssh', 'salt-syndic', 'salt-unity', 'spm'] %}

# remember that the top level cmd.run statements here are instructions to the
# salt-ssh minion, not the salt actually being tested
utils_installed:
  cmd.run:
    - names:
      {% for util in utils %}
      - '{{ util }} --help 1> /dev/null ; ( exit $? )'
      {% endfor %}

key:
  cmd.run:
    - name: salt-key -L

versions:
  cmd.run:
    - names:
      - salt --versions-report
      - salt {{ minion_id }} test.versions_report

grains:
  cmd.run:
    - names:
      - salt {{ minion_id }} grains.item os
      - salt {{ minion_id }} grains.item pythonversion
      - salt {{ minion_id }} grains.setval key val

pillar:
  cmd.run:
    - names:
      - salt {{ minion_id }} pillar.items

output:
  cmd.run:
    - names:
      - salt --output=yaml {{ minion_id }} test.fib 7
      - salt --output=json {{ minion_id }} test.fib 7

exec:
  cmd.run:
    - names:
      - salt {{ minion_id }} cmd.run 'ls -lah /'
      - salt {{ minion_id }} user.list_users
      - salt {{ minion_id }} network.arp

state_file:
  file.managed:
    - name: /srv/salt/states.sls
    - makedirs: True
    - contents: |
        update:
          pkg.installed:
            - name: htop
        salt_dude:
          user.present:
            - name: dude
            - fullname: Salt Dude

state:
  cmd.run:
    - names:
      - salt {{ minion_id }} state.sls states
    - require:
      - file: state_file
