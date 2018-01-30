{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

{% if params.test_os == 'MacOS' %}

    {% set run_os = 'macosx' %}

{% endif %}

include:
  - test_run.minion_only.{{ run_os }}
