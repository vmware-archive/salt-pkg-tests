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
  {% set pkgs = versioned_pkgs %}
{% endif %}

{% set dev = 'dev/' if salt['pillar.get']('dev') else '' %}
{% if pillar.get('new_repo') %}
  {% set repo_path = '{0}apt/ubuntu/{1}/{2}/{3}'.format(dev, os_release, os_arch, branch) %}
{% else %}
  {% set repo_path = '{0}apt/ubuntu/ubuntu{1}/{2}'.format(dev, os_major_release, branch) %}
{% endif %}
{% set repo_key = 'SALTSTACK-GPG-KEY.pub' %}


get-key:
  cmd.run:
    - name: wget -O - https://repo.saltstack.com/{{ repo_path }}/{{ repo_key }} | apt-key add -

add-repository:
  file.append:
    - name: /etc/apt/sources.list
    - text: |

        deb http://repo.saltstack.com/{{ repo_path }} {{ os_code_name }} main
    - require:
      - cmd: get-key

update-package-database:
  module.run:
    - name: pkg.refresh_db
    - require:
      - file: add-repository

upgrade-packages:
  pkg.uptodate:
    - name: uptodate
    - require:
      - module: update-package-database

install-salt:
  pkg.installed:
    - name: salt-pkgs
    - pkgs: {{ pkgs }}
    - require:
      - pkg: upgrade-packages

install-salt-backup:
  cmd.run:
    - name: aptitude -y install {{ pkgs | join(' ') }}
    - onfail:
      - pkg: install-salt
