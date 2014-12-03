nclude:
  - test_install.install_salt

{% set distro = salt['grains.get']('id', '')  %}

# Add SaltStack's Testing PPA & Debian Backports
sources_list_prep:
  file.append:
    - name: /etc/apt/sources.list
{% if distro == 'squeeze' %}
    - text: |
        ####################
        # Enable SaltStack's package testing repository
        deb http://debian.saltstack.com/debian squeeze-testing main
        ####################
        # Enable Debian's Backports repository
        deb http://backports.debian.org/debian-backports squeeze-backports main contrib non-free
{% else %}
    - text: |
        ####################
        # Enable SaltStack's package testing repository
        deb http://debian.saltstack.com/debian {{ distro }}-testing main
{% endif %}

# Update Debian and Ubuntu Mirrors
apt_update:
  cmd.run:
    - name: apt-get update -y
    - require:
      - file: sources_list_prep
    - require_in:
      - cmd: salt-master
      - cmd: salt-minion
      - cmd: salt-api
      - cmd: salt-cloud
      - cmd: salt-ssh
      - cmd: salt-syndic
