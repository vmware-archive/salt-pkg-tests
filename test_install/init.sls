{% set os_family = salt['grains.get']('os_family', '') %}
{% set os_major_release = salt['grains.get']('osmajorrelease', '') %}
{% set service_type = 'service' %}
{% set testing = pillar.get('testing', 'false') %}

# Decipher OS and set the package repository type and associated command
{% if os_family == 'Arch' %}

    {% set install_type = pillar.get('pkg_repo', 'arch') %}

{% elif os_family == 'RedHat' %}

    # CentOS/RHEL 5 is only available from salt's COPR repo - set this as default
    {% if os_major_release == '5' %}
        {% set install_type = pillar.get('pkg_repo', 'copr') %}
    {% else %}
        {% set install_type = pillar.get('pkg_repo', 'epel') %}

        # RHEL/CentOS 6 usues systemctl
        {% if os_major_release != '6' %}
            {% set service_type = 'systemctl' %}
        {% endif %}
    {% endif %}

{% elif os_family == 'Debian' %}

    {% set install_type = pillar.get('pkg_repo', 'debian') %}

{% endif %}

# Includes determine where to go next
include:
  - test_install.{{ install_type }}

# TODO: Likely a useful place to so some systemctl or service start/restart/stop tests
# TODO: Or we could still use the includes to start messing with services after installations
