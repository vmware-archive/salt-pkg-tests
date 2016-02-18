{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}


{# Test SaltStack packages #}
{% if params.use_saltstack %}

# SaltStack formula will determine which repository SLS to include
include:
  - test_install.saltstack

{# Test distribution or community packages #}
{% else %}

  {# Set package repository from platform information #}
  {% if params.os_family == 'Arch' %}

    {% set pkg_repo = params.pkg_repo or 'arch' %}

  {% elif params.os_family == 'RedHat' %}

    {# CentOS/RHEL 5 is only available from salt's COPR repo - set this as default #}
    {% if on_rhel_5 %}
      {% set pkg_repo = params.pkg_repo or 'copr' %}
    {% else %}
      {% set pkg_repo = params.pkg_repo or 'epel' %}
    {% endif %}

  {% elif params.os_family == 'Debian' %}

    {% set pkg_repo = params.pkg_repo or 'debian' %}

  {% elif params.os_family == 'Suse' %}

    {% set pkg_repo = params.pkg_repo or 'suse' %}

  {% endif %}

# Route into selected SLS file containing the install states
include:
  - test_install.{{ pkg_repo }}

{% endif %}
