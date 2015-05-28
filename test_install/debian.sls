{% set os = salt['grains.get']('os', '') %}
{% set distro = salt['grains.get']('oscodename', '')  %}
{% set pkgs = ['salt-master', 'salt-minion', 'salt-api', 'salt-cloud', 'salt-ssh', 'salt-syndic'] %}
{% set testing = pillar.get('testing', 'False') %}

# Add testing repos for each Debian Distro
{% if testing == 'True' and os =='Debian' %}

# Get the GPG key for Debian Packages
debian:
  cmd.run:
    - name: wget -O - http://debian.saltstack.com/debian-salt-team-joehealy.gpg.key|apt-key add -
    - require_in:
      - file: source_prep

# Add SaltStack's Testing PPA & Debian Backports
source_prep:
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

{% else %}

{% if distro == 'precise' %}
add_python_software_properties
  cmd.run:
    - name: apt-get -y install python-software-properties

{% endif %}

{% if testing == 'True' %}

# Add saltstack/testing repo for Ubuntu releases
add_apt_repo:
  cmd.run:
    - name: add-apt-repository ppa:saltstack/salt-testing

{% else %}

add_apt_repo:
  cmd.run:
    - name: add-apt-repository ppa:saltstack/salt

{% endif %}

{% endif %}

# Update Mirrors
apt_update:
  cmd.run:
    - name: apt-get update -y

# Install salt packages
{% for pkg in pkgs %}
{{ pkg }}:
  cmd.run:
    - name: apt-get -y install {{ pkg }}
{% endfor %}
