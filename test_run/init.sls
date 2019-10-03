{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}
{% set systemd_exists = salt['cmd.run']('pidof systemd') %}
{% set upgrade = salt['pillar.get']('upgrade') %}

include:
  - test_run.check_imports
{# restart services that don't auto start on upgrade #}
{% if ('2016' in params.salt_version or not systemd_exists) and upgrade %}
  - test_run.restart_services
{% endif %}
{% if params.minion_only %}
{# minion only #}
  - test_run.minion_only
{% else %}
  - test_run.master_minion
{% if params.os in ('CentOS', 'Redhat', 'Amazon', 'Debian', 'Ubuntu') %}
  - test_run.api
{% endif %}
{% endif %}
