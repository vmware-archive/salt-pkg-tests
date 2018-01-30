{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}


{# Set package repository from platform information #}
{% if params.os_family == 'RedHat' and 'Amazon' not in params.os %}

  {% set pkg_repo = params.pkg_repo or 'rhel' %}

{% elif params.os == 'Amazon' %}

    {% set pkg_repo = params.pkg_repo or 'amazon' %}

{% elif params.os == 'Debian' or params.os == 'Raspbian' %}

    {% set pkg_repo = params.pkg_repo or 'debian' %}

{% elif params.os == 'Ubuntu' %}

  {% set pkg_repo = params.pkg_repo or 'ubuntu' %}

{% elif params.os == 'MacOS' %}

  {% set pkg_repo = params.pkg_repo or 'macosx' %}

{% endif %}

# Route into selected SLS file containing the install states
include:
  - test_install.saltstack.{{ pkg_repo }}
