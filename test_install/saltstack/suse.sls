{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

{% set salt_version = salt['pillar.get']('salt_version', '') %}

{# Determine Suse_Version #}
{% set suse_version = params.os + params.os_release %}
{% if suse_version == 'openSUSE13.1' %}
  {% set suse_version = 'openSUSE_13.2' %}
{% elif suse_version == 'SUSE11.4' %}
  {% set suse_version = 'SLE_11_SP4' %}
{% elif suse_version == 'SUSE12.1' %}
  {% set suse_version = 'SLE_12' %}
{% elif suse_version == 'openSUSE Leap42.1' %}
  {% set suse_version = 'openSUSE_Leap_42.1' %}
{% endif %}

{# Paramters used with repo package install #}
{% set repo_pkg_url = 'http://repo.saltstack.com/{0}opensuse/{1}/systemsmanagement:saltstack.repo'.format(params.dev, suse_version) %}

{# Paramters used to manually add repo file #}
{% set repo_url = 'https://repo.saltstack.com/{0}opensuse/{1}'.format(params.dev, suse_version) %}
{% set gpg_url = 'https://repo.saltstack.com/{0}opensuse/{1}/repodata/repomd.xml.key'.format(params.dev, suse_version) %}


{% if params.use_repo_pkg %}
add-suse-repo:
  cmd.run:
    - name: zypper addrepo {{ repo_pkg_url }}
{% else %}
add-suse-repo:
  file.managed:
    - name: /etc/zypp/repos.d/saltstack.repo
    - makedirs: True
    - contents: |
        [saltstack]
        name=SaltStack, dependencies, and addons ({{ suse_version }})
        type=rpm-md
        baseurl={{ repo_url }}
        gpgcheck=1
        gpgkey={{ gpg_url }}
        enabled=1
{% endif %}

get-key:
  cmd.run:
    - name: sudo zypper --gpg-auto-import-keys refresh

refresh:
  module.run:
    - name: pkg.refresh_db
    - require:
      {% if params.use_repo_pkg %}
      - cmd: get-key
      {% else %}
      - file: add-suse-repo
      {% endif %}

# Install salt packages
install-salt:
  pkg.installed:
    - name: salt-pkgs
    - pkgs: {{ params.pkgs }}
    - require:
      - module: refresh

install-salt-backup:
  cmd.run:
    - name: zypper --non-interactive install {{ params.versioned_pkgs | join(' ') }}
    - onfail:
      - pkg: install-salt
