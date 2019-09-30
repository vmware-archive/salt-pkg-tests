{% set minion_id = '*win*' %}
{% set timeout = '-t 599' %}


# The top level cmd.run statements here are instructions to the salt-ssh minion,
# not the salt being tested
disable_firewalld:
  service.dead:
    - name: firewalld

key:
  cmd.run:
    - names:
      - sleep 60
      - salt-key -L

versions:
  cmd.run:
    - names:
      - salt {{ minion_id }} test.versions_report {{ timeout }}

versions1:
  cmd.run:
    - names:
      - salt {{ minion_id }} test.versions_report {{ timeout }}

versions2:
  cmd.run:
    - names:
      - salt {{ minion_id }} test.versions_report {{ timeout }}

grains:
  cmd.run:
    - names:
      - salt {{ minion_id }} grains.item os {{ timeout }}
{# run this command twice as a workaround for an issue with windows and running second command during automation #}
      - salt {{ minion_id }} grains.item os {{ timeout }}
      - salt {{ minion_id }} grains.item pythonversion {{ timeout }}
      - salt {{ minion_id }} grains.setval key val {{ timeout }}

pillar:
  cmd.run:
    - names:
      - salt {{ minion_id }} pillar.items {{ timeout }}

output:
  cmd.run:
    - names:
      - salt --output=yaml {{ minion_id }} test.fib 7 {{ timeout }}
      - salt --output=json {{ minion_id }} test.fib 7 {{ timeout }}

exec:
  cmd.run:
    - names:
      - salt {{ minion_id }} cmd.run 'ipconfig' {{ timeout }}
      - salt {{ minion_id }} user.list_users {{ timeout }}

state_file:
  file.managed:
    - name: /srv/salt/states.sls
    - makedirs: True
    - contents: |
        create_empty_file:
          file.managed:
            - name: C:\\salt\test.txt
        salt_dude:
          user.present:
            - name: dude
            - fullname: Salt Dude

state:
  cmd.run:
    - names:
      - salt {{ minion_id }} state.sls states {{ timeout }}
    - require:
      - file: state_file

versions3:
  cmd.run:
    - names:
      - salt {{ minion_id }} test.versions_report {{ timeout }}

salt-call:
  cmd.run:
    - names:
      - salt {{ minion_id }} cmd.run "C://salt/salt-call --local sys.doc none" {{ timeout }}
      - salt {{ minion_id }} cmd.run "C://salt/salt-call state.apply states" {{ timeout }}
      - salt {{ minion_id }} cmd.run "C://salt/salt-call --local sys.doc aliases.list_aliases" {{ timeout }}
