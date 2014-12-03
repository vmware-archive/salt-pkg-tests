{% set os = salt['grains.get']('os', '') %}
{% set os_family = salt['grains.get']('os_family', '') %}

{% if os_family == 'RedHat' %}
  {% set pkg_cmd = 'yum -y install' %}
{% elif os == 'Debian' %}
  {% set pkg_cmd = 'apt-get -y install'  %}
{% endif %}

{% set pkgs = ['salt-master', 'salt-minion', 'salt-api', 'salt-cloud', 'salt-ssh', 'salt-syndic'] %}

# Install salt packages
{% for pkg in pkgs %}
{{ pkg }}:
  cmd.run:
    - name: {{ pkg_cmd}} {{ pkg }}
{% endfor %}
