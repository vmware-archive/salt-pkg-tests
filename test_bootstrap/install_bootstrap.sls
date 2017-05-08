{% set bootstrap_script = '/tmp/bootstrap-salt.sh' %}
{% set cmd_args = salt['pillar.get']('cmd_args') %}
{% set install_version = salt['pillar.get']('install_version') %}

{% if install_version = 'develop ' %}
  {% set script_source = 'https://raw.githubusercontent.com/saltstack/salt-bootstrap/develop/bootstrap-salt.sh' %}
{% elif install_version = 'live' %}
  {% set script_source = 'https://bootstrap.saltstack.com' %}
{% endif %}

add_bootstrap_script:
  file.managed:
    - name: {{ bootstrap_script }}
    - source: {{ script_source }}

run_bootstrap:
  cmd.run:
    - name: {{ bootstrap_script }} {{ cmd_args }}
