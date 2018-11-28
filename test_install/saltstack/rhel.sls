{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

{# Parameters used with repo package install #}
{% set branch = params.salt_version.rsplit('.', 1)[0] %}

{% if params.on_amazon %}
  {% set repo_pkg = 'salt-amzn-repo-{0}{1}.rpm'.format(branch, params.repo_pkg_version) %}
  {% set repo_pkg_url = 'https://repo.saltstack.com/{0}{1}/amazon/{2}'.format(params.dev, params.py_dir, repo_pkg) %}
{% elif params.test_rc_pkgs %}
  {% set repo_pkg = 'salt-amzn-repo-{0}{1}.rpm'.format(branch, params.repo_pkg_version) %}
  {% set repo_pkg_url = 'https://repo.saltstack.com/{0}salt_rc/{1}/amazon/{2}'.format(params.dev, params.py_dir, repo_pkg) %}
{% else %}
  {% set repo_pkg = 'salt-repo-{0}{1}.el{2}.noarch.rpm'.format(branch, params.repo_pkg_version, params.os_major_release ) %}
  {% set repo_pkg_url = 'https://repo.saltstack.com/{0}{1}/redhat/{2}'.format(params.dev, params.py_dir, repo_pkg) %}
{% endif %}

{# Parameters used with pkgrepo.managed install #}
{% set release = 6 if params.on_amazon else '$releasever' %}

{% if params.use_latest %}
  {% set repo_url = 'https://{0}repo.saltstack.com/{1}{2}/redhat/{3}/$basearch/latest'.format(params.repo_auth, params.dev, params.py_dir, release) %}
{% elif params.test_rc_pkgs %}
  {% set repo_url = 'https://repo.saltstack.com/{0}salt_rc/{1}/redhat/{2}/$basearch'.format(params.dev, params.py_dir, release) %}
{% else %}
  {% set repo_url = 'https://{0}repo.saltstack.com/{1}{2}/redhat/{3}/$basearch/archive/{4}' %}
  {% set repo_url = repo_url.format(params.repo_auth, params.dev, params.py_dir, release, params.salt_version) %}
{% endif %}

{% set key_name = 'SALTSTACK-EL5-GPG-KEY.pub' if params.on_rhel_5 else 'SALTSTACK-GPG-KEY.pub' %}
{% set key_url = '{0}/{1}'.format(repo_url, key_name) %}

{% set fips_enabled = salt['cmd.run']('cat /proc/sys/crypto/fips_enabled') %}
{% if params.python3 and fips_enabled != 1 %}
install_IUS:
  pkg.installed:
    - sources:
      - ius-release: https://centos7.iuscommunity.org/ius-release.rpm

install_python34:
  pkg.installed:
    - name: python34u
{% endif %}

setup_ntp:
  cmd.run:
    - names:
      - yum install ntp -y
      - ntpdate -s time.nist.gov

{% if params.use_repo_pkg %}
add-repo:
  cmd.run:
    {% if params.on_rhel_5 %}
    - name: wget {{ repo_pkg_url }} ; rpm -iv {{ repo_pkg }} ; rm -f {{ repo_pkg }}
    {% else %}
    - name: yum install -y {{ repo_pkg_url }}
    {% endif %}
    - unless:
      - rpm -q {{ repo_pkg.split('.rpm')[0] }}
replace_repo_file:
  file.replace:
    - name: /etc/yum.repos.d/salt-{{ branch }}.repo
    - pattern: 'repo.saltstack.com/yum/redhat'
    - repl: 'repo.saltstack.com/{{ params.dev }}yum/redhat'
    - require:
      - cmd: add-repo
{% else %}
add-repo:
  pkgrepo.managed:
    - name: saltstack-{{ params.repo_version }}
    - humanname: SaltStack {{ params.repo_version }} repo for RHEL/CentOS $releasever
    - baseurl: {{ repo_url }}
    - gpgcheck: 1
    - gpgkey: {{ key_url }}
{% endif %}

update-package-database:
  module.run:
    - name: pkg.refresh_db
    - require:
      {% if params.use_repo_pkg %}
      - cmd: add-repo
      {% else %}
      - pkgrepo: add-repo
      {% endif %}

{% if params.crypto_library != 'default' %}
install-crypto:
  cmd.run:
    - name: yum -y install {{ params.crypto_library }}
{% endif %}

{% if params.upgrade %}
upgrade-salt:
  cmd.run:
    - name: yum -y update {{ params.pkgs | join(' ') }}
wait_for_upgrade_salt:
  cmd.run:
    - name: sleep 60

{% else %}
install-salt:
  cmd.run:
    - name: yum -y install {{ params.versioned_pkgs | join(' ') }}
    - require:
      - module: update-package-database

{% endif %}

{% if params.os_major_release == '7' %}
check_base_dir:
  cmd.script:
    - name: check-base-directory
    - source: salt://test_install/files/check_base_dir.py
{% set staging = True if pillar['dev'] == 'staging' else False %}
    {% if staging %}
    - args: "-v {{ params.salt_version }} -o {{ params.os_major_release }} -d {{ params.os_family }} -s -u {{ params.repo_user }} -p {{ params.repo_passwd }}"
    {% else %}
    - args: "-v {{ params.salt_version }} -o {{ params.os_major_release }} -d {{ params.os_family }}"
    {% endif %}
{% endif %}
