{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

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

{% for pkg in params.pkgs %}
{{ pkg }}:
  cmd.run:
    - name: {{ install_cmd }} {{ pkg }}
    - requires:
      - module: refresh
{% endfor %}

{% else %}

{% set install_cmd = 'dnf -y install' %}

install_from_repo:
  cmd.run:
    - name: {{ install_cmd }} {{ params.pkgs | join(' ') }}

{% endif %}
