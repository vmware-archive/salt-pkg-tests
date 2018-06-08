{% set linux_master = pillar.get('linux_master', '') %}
{% set test_rc_pkgs = pillar.get('test_rc_pkgs', 'False') %}
{% set repo_auth = pillar.get('repo_auth') %}
{% set staging = pillar.get('staging') %}
{% set salt_version = pillar.get('salt_version') %}
{% set python3 = pillar.get('python3', False) %}
{% set host = pillar.get('host', '') %}
{% set win_arch = pillar.get('win_arch') %}
{% set profile = pillar.get('profile') %}
{% set pkg = 'Salt-Minion-{0}-Py{1}-{2}-Setup.exe'.format(salt_version, 3 if python3 else '2', win_arch) %}
{% set source = 'http://{0}repo.saltstack.com/{1}{2}/windows/{3}'.format(repo_auth, staging, 'salt_rc' if test_rc_pkgs else '', pkg) %}
{% set git_user = pillar.get('git_user') %}
{% set source_hash = source + '.md5' %}

get_winexe:
  file.managed:
    - name: /etc/salt/windows/{{ pkg }}
    - source: {{ source }}
    - skip_verify: True
    - makedirs: True

manage_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/windows-{{ host }}.map
    - source: salt://test_orch/states/windowsmap
    - template: jinja
    - makedirs: True
    - context:
        pkg: {{ pkg }}
        profile: {{ profile }}
        git_user: {{ git_user }}
