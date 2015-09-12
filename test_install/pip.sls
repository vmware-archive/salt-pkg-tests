{% set os_family = salt['grains.get']('os_family', '') %}
{% set os_ = salt['grains.get']('os', '') %}
{% set salt_version = salt['pillar.get']('salt_version', '') %}
{% set pkg_version = salt['pillar.get']('pkg_version', '1') %}

{% set on_redhat = os_family == 'RedHat' %}
{% set on_fedora = os_family == 'Fedora' %}

{% set url_pkg_ver = salt['pillar.get']('pkg_version', '').lstrip('v') %}
{% set pkg_url = 'https://pypi.python.org/packages/source/s/salt/salt-{0}.tar.gz'.format(url_pkg_ver) %}


{% if on_redhat and not on_fedora %}
epel:
  pkg.installed:
    - name: epel-release
{% endif %}

refresh:
  module.run:
    - name: pkg.refresh_db
    {% if on_redhat and not on_fedora %}
    - require:
      - pkg: epel
    {% endif %}
    - require_in:
      - pkg: get-pip
      - pkg: get-salt

{% if on_redhat %}
refresh_backup:
  cmd.run:
    - name: yum -y makecache
    - onfail:
      - module: refresh
{% endif %}

get-pip:
  pkg.installed:
    - name: python-pip

get-salt:
  cmd.run:
    - name: wget {{ pkg_url }}

update-pip:
  cmd.run:
    - name: pip install --upgrade pip
    - require:
      - pkg: get-pip

install-pkgs:
  cmd.run:
    - name: yum -y install {{ pkg_files | join(' ') }}
    - require:
      - cmd: get-salt
      - cmd: update-pip
