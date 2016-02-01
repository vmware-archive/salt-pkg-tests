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
  {% set pkgs = versioned_pkgs %}
{% endif %}

{% set dev = salt['pillar.get']('dev', '') %}
{% set dev = dev + '/' if dev else '' %}

{% if pillar.get('new_repo', True) %}
  {% set repo_path = '{0}yum/redhat/{1}/{2}/{3}'.format(dev, os_major_release, os_arch, branch) %}
{% else %}
  {% set repo_path = '{0}yum/rhel{1}'.format(dev, os_major_release) %}
{% endif %}
{% set repo_key = 'SALTSTACK-EL5-GPG-KEY.pub' if on_rhel_5 else 'SALTSTACK-GPG-KEY.pub' %}


get-key:
  cmd.run:
    {% if on_rhel_5 %}
    - name: wget https://repo.saltstack.com/{{ repo_path }}/{{ repo_key }} ; rpm --import {{ repo_key }} ; rm -f {{ repo_key }}
    {% else %}
    - name: rpm --import https://repo.saltstack.com/{{ repo_path }}/{{ repo_key }}
    {% endif %}

add-repository:
  file.managed:
    - name: /etc/yum.repos.d/saltstack.repo
    - makedirs: True
    - contents: |
        [saltstack-repo]
        name=SaltStack repo for RHEL/CentOS $releasever
        baseurl=https://repo.saltstack.com/{{ repo_path }}
        enabled=1
        gpgcheck=1
        gpgkey=http://repo.saltstack.com/yum/rhel{{ os_major_release }}/{{ repo_key }}
    - require:
      - cmd: get-key

update-package-database:
  module.run:
    - name: pkg.refresh_db
    - require:
      - file: add-repository

update-package-database-backup:
  cmd.run:
    - name: yum -y makecache
    - onfail:
      - module: update-package-database

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
    - name: yum -y install {{ pkgs | join(' ') }}
    - onfail:
      - pkg: install-salt
