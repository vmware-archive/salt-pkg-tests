{% set os_ = salt['grains.get']('os', '') %}
{% set os_arch = salt['grains.get']('osarch', '') %}
{% set os_release = salt['grains.get']('osrelease', '') %}
{% set os_major_release = os_release.split('.')[0] %}
{% set os_code_name = salt['grains.get']('oscodename', '')  %}

{% set salt_version = salt['pillar.get']('salt_version', '') %}
{% set pkg_version = salt['pillar.get']('pkg_version', '1') %}
{% set pkgs = ['salt-master', 'salt-minion', 'salt-api', 'salt-cloud', 'salt-ssh', 'salt-syndic'] %}

{% if salt['pillar.get']('branch') %}
  {% set branch = salt['pillar.get']('branch') %}
{% else %}
  {% set branch = salt_version.rsplit('.', 1)[0] if salt_version else 'latest' %}
{% endif %}

{% if salt_version %}
  {% set versioned_pkgs = [] %}
  {% for pkg in pkgs %}
    {% do versioned_pkgs.append(pkg + '=' + salt_version + '+ds-' + pkg_version) %}
  {% endfor %}
{% endif %}

{% set dev = salt['pillar.get']('dev', '') %}
{% set dev = dev + '/' if dev else '' %}

{% set repo_path = '{0}apt/ubuntu/{1}/{2}/{3}'.format(dev, os_release, os_arch, branch) %}


add-repo:
  pkgrepo.managed:
    - name: deb http://repo.saltstack.com/{{ repo_path }} {{ os_code_name }} main
    - file: /etc/apt/sources.list.d/saltstack.list
    - key_url: https://repo.saltstack.com/{{ repo_path }}/SALTSTACK-GPG-KEY.pub

update-package-database:
  module.run:
    - name: pkg.refresh_db
    - require:
      - pkgrepo: add-repo

install-salt:
  pkg.installed:
    - names: {{ pkgs }}
    - version: {{ salt_version }}
    - require:
      - module: update-package-database

install-salt-backup:
  cmd.run:
    - name: aptitude -y install {{ versioned_pkgs | join(' ') }}
    - onfail:
      - pkg: install-salt
