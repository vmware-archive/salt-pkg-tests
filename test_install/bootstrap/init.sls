{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}
{% set bootstrap_repo = salt['pillar.get']('bootstrap_repo', 'saltstack') %}

get_bootstrap:
  cmd.run:
    - name: curl -o bootstrap-salt.sh -L https://bootstrap.saltstack.com

install_bootstrap:
  cmd.run:
    - name: sudo sh bootstrap-salt.sh -q -M -g https://github.com/{{ bootstrap_repo }}/salt.git git v{{ params.salt_version }}
