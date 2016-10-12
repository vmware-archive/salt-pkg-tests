{% set os_ = salt['grains.get']('os', '') %}
{% set os_major_release = salt['grains.get']('osmajorrelease', '') %}
{% set salt_version = salt['pillar.get']('salt_version', '') %}
{% set pkg_version = salt['pillar.get']('pkg_version', '1') %}
{% set dev = salt['pillar.get']('dev', 'False') %}

{% set on_fedora = os_ == 'Fedora' %}

{% set url_base = 'https://kojipkgs.fedoraproject.org/packages/salt/' %}
{% set pkgs = ['salt', 'salt-master', 'salt-minion', 'salt-api', 'salt-cloud', 'salt-ssh', 'salt-syndic'] %}

{% set rh_version = 'fc' if on_fedora else 'el' %}
{% set pkg_version = '{0}.{1}{2}'.format(pkg_version, rh_version, os_major_release) %}

{% set pkg_urls = {} %}
{% for pkg in pkgs %}
  {% do pkg_urls.update({pkg: url_base + salt_version + '/' + pkg_version + '/noarch/' + pkg + '-' + salt_version + '-' + pkg_version + '.noarch.rpm'}) %}
{% endfor %}

{% set pkg_files = [] %}
{% for pkg in pkgs %}
  {% do pkg_files.append(pkg + '-' + salt_version + '-' + pkg_version + '.noarch.rpm') %}
{% endfor %}


{% if dev == 'staging' %}

refresh:
  module.run:
    - name: pkg.refresh_db
    {% if not on_fedora %}
    - requires:
      - pkg: epel
    {% endif %}

refresh_backup:
  cmd.run:
    - name: yum -y makecache
    - onfail:
      - module: refresh

{% for pkg in pkgs %}
get-{{ pkg }}:
  cmd.run:
    - name: wget {{ pkg_urls[pkg] }}
    - requires:
      - module: refresh
    - require_in:
      - cmd: install-pkgs
{% endfor %}

install-pkgs:
  cmd.run:
    - name: dnf -y install {{ pkg_files | join(' ') }}

{% else %}

install_from_repo:
  cmd.run:
    - name: dnf -y install {{ pkgs | join(' ') }}

{% endif %}
