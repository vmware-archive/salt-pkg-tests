{% set os_grain = salt['grains.get']('os', '') %}
{% set osmajorrelease = salt['grains.get']('osmajorrelease', '') %}

{% if os_grain == 'CentOS' %}
  {% if osmajorrelease == '6' %}
    {% set rh_version = '1.el6' %}
  {% elif osmajorrelease == '7' %}
    {% set rh_version = '1.el7' %}
  {% endif %}
{% elif os_grain == 'Fedora' %}
  {% if osmajorrelease == '20' %}
    {% set rh_version = '1.fc20' %}
  {% elif osmajorrelease == '21' %}
    {% set rh_version = '1.fc21' %}
  {% endif %}
{% endif %}


{% set install_cmd = 'yum -y install' %}
{% set salt_version = '2015.5.1' %}
{% set url_base = 'https://kojipkgs.fedoraproject.org/packages/salt/' %}
{% set pkgs = ['salt', 'salt-master', 'salt-minion', 'salt-api', 'salt-cloud', 'salt-ssh', 'salt-syndic'] %}

{% for pkg in pkgs %}
  {% set pkg = url_base + salt_version + '/' + rh_version + '/noarch/' + pkg + '-' + rh_version + '.noarch.rpm' %}
{% endfor %}


# Install salt packages
koji:
  cmd.run: 
    - name: {{ install_cmd }} {{ pkgs | join(' ') }}
