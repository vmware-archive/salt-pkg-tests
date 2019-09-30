{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

{% set versioned_pkgs = salt['pillar.get']('versioned_pkgs') %}
{% set url_base = 'https://kojipkgs.fedoraproject.org/packages/salt/' %}
{% set rh_version = 'fc' %}
{% set fed_pkg_version = '{0}.{1}{2}'.format(params.fed_pkg_version, rh_version, params.os_major_release) %}

{# staging install #}
{% if params.dev %}
    {% set install_cmd = 'dnf -y --enablerepo=updates-testing install' %}
refresh:
  module.run:
    - name: pkg.refresh_db

refresh_backup:
  cmd.run:
    - name: dnf -y makecache
    - onfail:
      - module: refresh
  {% if params.upgrade %}
    {% set install_cmd = 'dnf -y --enablerepo=updates-testing update' %}
  {% endif %}

{% for pkg in params.pkgs %}
{% set pkg_name = pkg + '-' + params.salt_version + '-' + params.pkg_version + '.noarch.rpm' %}
get-{{ pkg }}:
  cmd.run: 
    - name: wget -O /tmp/{{ pkg_name }} {{ params.pkg_urls[pkg] }}
{% endfor %}

install-pkgs:
  cmd.run:
    - name: dnf -y install {{ params.pkg_files | join(' ') }}

{# live install #}
{% else %}

{% set install_cmd = 'dnf -y install' %}

{% if params.upgrade %}
  {% set install_cmd = 'dnf -y update' %}
upgrade-salt:
  cmd.run:
    - name: {{ install_cmd }} {{ params.pkgs | join(' ') }}
{% else %}

install_from_repo:
  cmd.run:
    - name: {{ install_cmd }} {{ params.pkgs | join(' ') }}
{% endif %}

{% endif %}
