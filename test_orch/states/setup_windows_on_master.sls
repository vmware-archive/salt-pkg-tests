{% set test_rc_pkgs = pillar.get('test_rc_pkgs', 'False') %}
get_winexe:
  file.managed:
    - name: /etc/salt/windows/Salt-Minion-{{ salt['pillar.get']('salt_version', '') }}-AMD64-Setup.exe
{% if test_rc_pkgs %}
    - source: http://repo.saltstack.com/{{ salt['pillar.get']('dev', '') }}salt_rc/windows/Salt-Minion-{{ salt['pillar.get']('salt_version', '') }}-AMD64-Setup.exe
    - source_hash: http://repo.saltstack.com/{{ salt['pillar.get']('dev', '') }}salt_rc/windows/Salt-Minion-{{ salt['pillar.get']('salt_version', '') }}-AMD64-Setup.exe.md5
{% else %}
    - source: http://repo.saltstack.com/{{ salt['pillar.get']('dev', '') }}windows/Salt-Minion-{{ salt['pillar.get']('salt_version', '') }}-AMD64-Setup.exe
    - source_hash: http://repo.saltstack.com/{{ salt['pillar.get']('dev', '') }}/windows/Salt-Minion-{{ salt['pillar.get']('salt_version', '') }}-AMD64-Setup.exe.md5
{% endif %}
    - makedirs: True

manage_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/windows.map
    - source: salt://test_orch/states/windowsmap
    - template: jinja
    - makedirs: True

add_reactor_file:
  file.managed:
    - name: /srv/reactor/win_reactor.sls
    - source: salt://test_orch/reactor/win_reactor
    - template: jinja
    - makedirs: True
