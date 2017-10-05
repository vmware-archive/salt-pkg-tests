{% set zone_template = salt['pillar.get']('zone_template') %}
zone_template:
  file.managed:
    - name: /tmp/{{ zone_template }}.xml
    - source: salt://test_orch/files/zone_template.xml
    - user: root
    - group: root
    - mode: 644
    - template: jinja
