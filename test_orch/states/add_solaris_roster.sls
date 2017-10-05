{% set solaris_master = salt['pillar.get']('solaris_master') %}
{% set solarism_user = salt['pillar.get']('solarism_user') %}
{% set solarism_passwd = salt['pillar.get']('solarism_passwd') %}
{% set solarism_host = salt['pillar.get']('solarism_host') %}

add_main_solaris:
  file.append:
    - name: /etc/salt/roster
    - text: |
        {{ solaris_master }}:
          host: {{ solarism_host }}
          user: {{ solarism_user }}
          passwd: {{ solarism_passwd }}
          sudo: True
