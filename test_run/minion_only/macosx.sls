{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}
{% set timeout = '-t 10' %}

{% set branch = params.salt_version.rsplit('.', 1)[0] %}
{% set pre_cmd = 'source /etc/profile;' %}

# The top level cmd.run statements here are instructions to the salt-ssh minion,
# not the salt being tested

disable_firewalld:
  service.dead:
    - name: firewalld


utils_installed:
  cmd.run:
    - names:
      {% for util in params.minion_utils %}
      - '{{ pre_cmd }} {{ util }} --help 1> /dev/null ; ( exit $? )'
      {% endfor %}
      - sleep 30

versions:
  cmd.run:
    - names:
      - salt {{ params.minion_id }} test.versions_report {{ timeout }}

grains:
  cmd.run:
    - names:
      - salt {{ params.minion_id }} grains.item os {{ timeout }}
      - salt {{ params.minion_id }} grains.item pythonversion {{ timeout }}
      - salt {{ params.minion_id }} grains.setval key val {{ timeout }}

pillar:
  cmd.run:
    - names:
      - salt {{ params.minion_id }} pillar.items {{ timeout }}

output:
  cmd.run:
    - names:
      - salt --output=yaml {{ params.minion_id }} test.fib 7 {{ timeout }}
      - salt --output=json {{ params.minion_id }} test.fib 7 {{ timeout }}

exec:
  cmd.run:
    - names:
      - salt {{ params.minion_id }} cmd.run 'ls -lah /' {{ timeout }}
      - salt {{ params.minion_id }} user.list_users {{ timeout }}
      - salt {{ params.minion_id }} network.arp {{ timeout }}

state_file:
  file.managed:
    - name: {{ params.file_roots }}/states.sls
    - makedirs: True
    - contents: |
        salt_dude:
          user.present:
            - name: dude
            - fullname: Salt Dude

state:
  cmd.run:
    - names:
      - salt {{ params.minion_id }} state.sls states {{ timeout }}
    - require:
      - file: state_file

salt-call:
  cmd.run:
    - names:
      - salt {{ params.minion_id }} cmd.run "{{ pre_cmd }}salt-call --local sys.doc none" {{ timeout }}
      - salt {{ params.minion_id }} cmd.run "{{ pre_cmd }}salt-call state.apply states" {{ timeout }}
      - salt {{ params.minion_id }} cmd.run "{{ pre_cmd }}salt-call --local sys.doc aliases.list_aliases" {{ timeout }}
