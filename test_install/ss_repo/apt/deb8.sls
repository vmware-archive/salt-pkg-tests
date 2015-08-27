{% set os_ = salt['grains.get']('os', '') %}
{% set os_major_release = salt['grains.get']('osmajorrelease', '') %}
{% set distro = salt['grains.get']('oscodename', '')  %}

{% set salt_version = salt['pillar.get']('salt_version', '') %}
{% set pkgs = ['salt-master', 'salt-minion', 'salt-api', 'salt-cloud', 'salt-ssh', 'salt-syndic'] %}

get-key:
  cmd.run:
    - name: wget -O - https://repo.saltstack.com/apt/deb{{ os_major_release }}/SALTSTACK-GPG-KEY.pub | apt-key add -

add-repository:
  file.append:
    - name: /etc/apt/sources.list
    - text: |

        ####################
        # Enable SaltStack's package repository
        deb http://repo.saltstack.com/apt/deb{{ os_major_release }} {{ distro }} contrib
    - require:
      - cmd: get-key

update-package-database:
  module.run:
    - name: pkg.refresh_db
    - require:
      - file: add-repository

upgrade-packages:
  pkg.uptodate:
    - name: pkg.refresh_db
    - require:
      - module: update-package-database

install-salt:
  cmd.run:
    - name: apt-get -y install {{ pkgs | join(' ') }}
    - require:
      - pkg: upgrade-packages
