{% set os_ = salt['grains.get']('os', '') %}
{% set os_major_release = salt['grains.get']('osrelease', '').split('.')[0] %}
{% set distro = salt['grains.get']('oscodename', '')  %}

{% if salt['pillar.get']('staging') %}
  {% set staging = 'staging/' %}
{% endif  %}
{% set salt_version = salt['pillar.get']('salt_version', '') %}
{% set branch = salt['pillar.get']('branch', '') %}
{% set pkgs = ['salt-master', 'salt-minion', 'salt-api', 'salt-cloud', 'salt-ssh', 'salt-syndic'] %}


get-key:
  cmd.run:
    - name: wget -O - https://repo.saltstack.com/apt/ubuntu/ubuntu{{ os_major_release }}/SALTSTACK-GPG-KEY.pub | apt-key add -

add-repository:
  file.append:
    - name: /etc/apt/sources.list
    - text: |

        ####################
        # Enable SaltStack's package repository
        deb http://repo.saltstack.com/{{ staging }}apt/ubuntu/ubuntu{{ os_major_release }}/{{ branch }} {{ distro }} main
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
