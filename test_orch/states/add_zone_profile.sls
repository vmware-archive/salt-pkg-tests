{% set zone_profile = salt['pillar.get']('zone_profile') %}
zone_profile:
  file.managed:
    - name: /tmp/{{ zone_profile }}
    - source: salt://test_orch/files/zone_profile
    - user: root
    - group: root
    - mode: 644
    - template: jinja
