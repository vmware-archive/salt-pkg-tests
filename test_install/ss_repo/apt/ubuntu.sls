{% set os_ = salt['grains.get']('os', '') %}
{% set os_major_release = salt['grains.get']('osrelease', '').split('.')[0] %}
{% set os_code_name = salt['grains.get']('oscodename', '')  %}

{% set staging = 'staging/' if salt['pillar.get']('staging') else '' %}
{% set salt_version = salt['pillar.get']('salt_version', '') %}
{% if salt['pillar.get']('branch') %}
  {% set branch = salt['pillar.get']('branch') %}
{% else %}
  {% set branch = salt_version.rsplit('.', 1)[0] if salt_version else 'latest' %}
{% endif %}

{% set pkgs = ['salt-master', 'salt-minion', 'salt-api', 'salt-cloud', 'salt-ssh', 'salt-syndic'] %}
{% if salt_version %}
  {% set versioned_pkgs = [] %}
  {% for pkg in pkgs %}
    {% do versioned_pkgs.append(pkg + '=' + salt_version + '+ds-1') %}
  {% endfor %}
  {% set pkgs = versioned_pkgs %}
{% endif %}


get-key:
  cmd.run:
    - name: wget -O - https://repo.saltstack.com/{{ staging }}apt/ubuntu/ubuntu{{ os_major_release }}/{{ branch }}/SALTSTACK-GPG-KEY.pub | apt-key add -

add-repository:
  file.append:
    - name: /etc/apt/sources.list
    - text: |

        ####################
        # Enable SaltStack's package repository
        deb http://repo.saltstack.com/{{ staging }}apt/ubuntu/ubuntu{{ os_major_release }}/{{ branch }} {{ os_code_name }} main
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
