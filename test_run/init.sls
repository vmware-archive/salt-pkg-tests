{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

include:
  - test_run.master_minion
{% if params.os in ('CentOS', 'Redhat', 'Amazon', 'Debian', 'Ubuntu') %}
  - test_run.api
{% endif %}
