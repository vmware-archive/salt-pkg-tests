{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

{% if params.use_latest %}
  {% set repo_url = 'https://repo.saltstack.com/{0}{1}apt/ubuntu/{2}/{3}/latest' %}
  {% set repo_url = repo_url.format(params.dev, params.rc_pkgs_url, params.os_release, params.os_arch) %}
{% else %}
  {% set repo_url = 'https://repo.saltstack.com/{0}{1}apt/ubuntu/{2}/{3}/archive/{4}' %}
  {% set repo_url = repo_url.format(params.dev, params.rc_pkgs_url, params.os_release, params.os_arch, params.salt_version) %}
{% endif %}

{% set key_url = '{0}/SALTSTACK-GPG-KEY.pub'.format(repo_url) %}

{# workaround until https://github.com/saltstack/salt/issues/27511 is fixed #}
{% set repo_url = 'http://' + repo_url.split('https://')[1] %}
{% set key_url = 'http://' + key_url.split('https://')[1] %}

{% if params.os_release == '16.04' %}
install-python-apt:
  pkg.installed:
    - name: python-apt
{% endif %}

install-https-transport:
  pkg.installed:
    - name: apt-transport-https

add-repo:
  pkgrepo.managed:
    - name: deb {{ repo_url }} {{ params.os_code_name }} main
    - file: /etc/apt/sources.list.d/salt-{{ params.repo_version }}.list
    - key_url: {{ key_url }}
    - require:
      - pkg: install-https-transport

update-package-database:
  module.run:
    - name: pkg.refresh_db
    - require:
      - pkgrepo: add-repo

{% if params.upgrade %}
upgrade-salt:
  cmd.run:
    - name: apt-get install -y -o Dpkg::Options::="--force-confdef" --only-upgrade {{ params.pkgs | join(' ') }}

{% set exists = salt['cmd.run']('pidof systemd') %}
{% if not exists %}
restart-salt:
  cmd.run:
    - names:
      - service salt-master restart
      - service salt-minion restart
    - require:
      - cmd: upgrade-salt
{% endif %}

{% else %}
install-salt:
  pkg.installed:
    - names: {{ params.pkgs }}
    - version: {{ params.salt_version }}
    - require:
      - module: update-package-database

install-salt-backup:
  cmd.run:
    - name: apt-get -y install {{ params.pkgs | join(' ') }}
    - onfail:
      - pkg: install-salt
{% endif %}
