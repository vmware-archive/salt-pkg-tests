{% set bootstrap_script = '/tmp/bootstrap-salt.sh' %}
{% set cmd_args = salt['pillar.get']('cmd_args') %}
{% set install_version = salt['pillar.get']('install_version', '') %}

{% if install_version == 'develop' %}
  {% set script_source = 'https://raw.githubusercontent.com/saltstack/salt-bootstrap/develop/bootstrap-salt.sh' %}
{% elif install_version == 'live' %}
  {% set script_source = 'https://bootstrap.saltstack.com' %}
{% endif %}

install_curl:
  pkg.installed:
    - name: curl

get_bootstrap:
  cmd.run:
    - name: curl {{ script_source }} -o {{ bootstrap_script }}; chmod 700 {{ bootstrap_script }}

run_bootstrap:
  cmd.run:
    {% if cmd_args %}
    - name: sh {{ bootstrap_script }} -P {{ cmd_args }}
    {% else %}
    - name: sh {{ bootstrap_script }} -P
    {% endif %}
