{% set linux_master = pillar.get('linux_master', '') %}
{% set test_rc_pkgs = pillar.get('test_rc_pkgs', 'False') %}
{% set repo_auth = pillar.get('repo_auth') %}
{% set staging = pillar.get('staging') %}
{% set salt_version = pillar.get('salt_version') %}
{% set python3 = pillar.get('python3', False) %}
{% set host = pillar.get('host', '') %}
{% set pkg = 'Salt-Minion-{0}-Py{1}-AMD64-Setup.exe'.format(salt_version, 3 if python3 else '2') %}
{% set source = 'http://{0}repo.saltstack.com/{1}{2}/windows/{3}'.format(repo_auth, staging, 'salt_rc' if test_rc_pkgs else '', pkg) %}
{% set source_hash = source + '.md5' %}

get_winexe:
  file.managed:
    - name: /etc/salt/windows/{{ pkg }}
    - source: {{ source }}
    - skip_verify: True
    - makedirs: True

manage_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/windows.map
    - source: salt://test_orch/states/windowsmap
    - template: jinja
    - makedirs: True
    - context:
        pkg: {{ pkg }}
