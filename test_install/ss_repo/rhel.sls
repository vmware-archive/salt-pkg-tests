{% set os_ = salt['grains.get']('os', '') %}
{% set os_arch = salt['grains.get']('osarch', '') %}
{% set os_major_release = salt['grains.get']('osmajorrelease', '') %}
{% set os_family = salt['grains.get']('os_family', '')  %}
{% set on_rhel_5 = True if os_family == 'RedHat' and os_major_release == '5' else False %}

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
    {% do versioned_pkgs.append(pkg + '-' + salt_version) %}
  {% endfor %}
{% endif %}

{% set dev = salt['pillar.get']('dev', '') %}
{% set dev = dev + '/' if dev else '' %}

{% set repo_pkg = 'salt-repo-{0}.el{1}.noarch.rpm'.format(branch, os_major_release) %}
{% set repo_pkg_url = 'https://repo.saltstack.com/{0}yum/redhat/{1}'.format(dev, repo_pkg) %}


add-repo:
  cmd.run:
    {% if on_rhel_5 %}
    - name: wget {{ repo_pkg_url }} ; rpm -iv {{ repo_pkg }} ; rm -f {{ repo_pkg }}
    {% else %}
    - name: rpm -iv install {{ repo_pkg_url }}
    {% endif %}
    - unless:
      - ls /etc/yum.repos.d/salt-{{ branch }}.repo

update-package-database:
  module.run:
    - name: pkg.refresh_db
    - require:
      - cmd: add-repo

install-salt:
  pkg.installed:
    - names: {{ pkgs }}
    - version: {{ salt_version }}
    - require:
      - module: update-package-database

install-salt-backup:
  cmd.run:
    - name: yum -y install {{ versioned_pkgs | join(' ') }}
    - onfail:
      - pkg: install-salt
