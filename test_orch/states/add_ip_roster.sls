add_ip_to_roster:
  file.managed:
    - name: /etc/salt/roster
    - source: salt://test_orch/states/roster_append
    - template: jinja
