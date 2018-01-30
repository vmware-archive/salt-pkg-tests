{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

{% if params.os == 'MacOS' %}

    {% set setup_os = 'macosx' %}

{% endif %}

include:
  - test_setup.minion_only.{{ setup_os }}
