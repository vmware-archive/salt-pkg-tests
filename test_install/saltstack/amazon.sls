{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

{# Parameters used with repo package install #}
{% set branch = params.salt_version.rsplit('.', 1)[0] %}

{% if params.use_latest %}
  {% set repo_url = 'https://{0}repo.saltstack.com/{1}{2}/amazon/latest/$basearch/latest'.format(params.repo_auth, params.dev, params.py_dir) %}
  {% set repo_pkg = 'salt-amzn-repo-{0}{1}.amzn1.noarch.rpm'.format(branch, params.repo_pkg_version) %}
  {% set repo_pkg_url = 'https://repo.saltstack.com/{0}{1}/amazon/{2}'.format(params.dev, params.py_dir, repo_pkg) %}
{% elif params.test_rc_pkgs %}
  {% set repo_url = 'https://repo.saltstack.com/{0}salt_rc/{1}/amazon/latest/$basearch'.format(params.dev, params.py_dir) %}
  {% set repo_pkg = 'salt-amzn-repo-{0}{1}.amzn1.noarch.rpm'.format(branch, params.repo_pkg_version) %}
  {% set repo_pkg_url = 'https://repo.saltstack.com/{0}salt_rc/{1}/amazon/{2}'.format(params.dev, params.py_dir, repo_pkg) %}
{% elif branch == '2016.3' %}
  {% set repo_url = 'https://{0}repo.saltstack.com/{1}{2}/redhat/6/$basearch/archive/{3}' %}
  {% set repo_url = repo_url.format(params.repo_auth, params.dev, params.py_dir, params.salt_version) %}
  {% set repo_pkg = 'salt-amzn-repo-{0}{1}.ami.noarch.rpm'.format(branch, params.repo_pkg_version) %}
  {% set repo_pkg_url = 'https://{0}repo.saltstack.com/{1}{2}/amazon/{3}'.format(params.repo_auth, params.dev, params.py_dir, repo_pkg) %}
{% else %}
  {% set repo_url = 'https://{0}repo.saltstack.com/{1}{2}/amazon/latest/$basearch/archive/{3}' %}
  {% set repo_url = repo_url.format(params.repo_auth, params.dev, params.py_dir, params.salt_version) %}
  {% set repo_pkg = 'salt-amzn-repo-{0}{1}.amzn1.noarch.rpm'.format(branch, params.repo_pkg_version) %}
  {% set repo_pkg_url = 'https://{0}repo.saltstack.com/{1}{2}/amazon/{3}'.format(params.repo_auth, params.dev, params.py_dir, repo_pkg) %}
{% endif %}

{% set key_name = 'SALTSTACK-GPG-KEY.pub' %}
{% set key_url = '{0}/{1}'.format(repo_url, key_name) %}


{% if params.use_repo_pkg %}
add-repo:
  cmd.run:
    - name: yum install -y {{ repo_pkg_url }}
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
add_priority:
  file.append:
    - name: /etc/yum.repos.d/saltstack-{{ params.repo_version }}.repo
    - text: |
        priority=10
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

{% if params.upgrade %}
upgrade-salt:
  cmd.run:
    - name: yum -y update {{ params.pkgs | join(' ') }}

{% else %}
install-salt:
  cmd.run:
    - name: yum -y install {{ params.versioned_pkgs | join(' ') }}
{% endif %}
