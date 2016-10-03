{% set minion_id = '*win*' %}


# The top level cmd.run statements here are instructions to the salt-ssh minion,
# not the salt being tested

key:
  cmd.run:
    - name: salt-key -L

versions:
  cmd.run:
    - names:
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
      - salt {{ minion_id }} cmd.run 'ipconfig'
      - salt {{ minion_id }} user.list_users

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
      - salt {{ minion_id }} state.sls states
    - require:
      - file: state_file

salt-call:
  cmd.run:
    - names:
      - salt {{ minion_id }} cmd.run "C://salt/salt-call --local sys.doc none"
      - salt {{ minion_id }} cmd.run "C://salt/salt-call state.apply states"
      - salt {{ minion_id }} cmd.run "C://salt/salt-call --local sys.doc aliases.list_aliases"
