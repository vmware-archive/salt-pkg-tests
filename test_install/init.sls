{% set os_family = salt['grains.get']('os_family', '') %}
{% set os_major_release = salt['grains.get']('osmajorrelease', '') %}

# Decipher OS and set the package repository type and associated command
{% if os_family == 'Arch' %}

    {% set install_type = pillar.get('pkg_repo', 'arch') %}

{% elif os_family == 'RedHat' %}

    # CentOS/RHEL 5 is only available from salt's COPR repo - set this as default
    {% if os_major_release == '5' %}
        {% set install_type = pillar.get('pkg_repo', 'copr') %}
    {% else %}
        {% set install_type = pillar.get('pkg_repo', 'epel') %}
    {% endif %}

{% elif os_family == 'Debian' %}

    {% set install_type = pillar.get('pkg_repo', 'debian') %}

{% elif os_family == 'Suse' %}

  {% set install_type = pillar.get('pkg_repo', 'suse') %}

{% endif %}

# Includes determine where to go next
include:
  - test_install.{{ install_type }}
