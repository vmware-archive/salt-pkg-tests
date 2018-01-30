{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

include:
{% if params.minion_only %}
{# minion only #}
  - test_setup.minion_only
{% else %}
  - test_setup.master_minion
{% if params.os in ('CentOS', 'Redhat', 'Amazon', 'Debian', 'Ubuntu') %}
  - test_setup.api
{% endif %}
{% endif %}
