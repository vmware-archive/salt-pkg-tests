{% set os_family = salt['grains.get']('os_family', '') %}
{% set os_ = salt['grains.get']('os', '') %}
{% set os_major_release = salt['grains.get']('osmajorrelease', '') %}
{% set pkgs = ['salt-master', 'salt-minion', 'salt-api', 'salt-cloud', 'salt-ssh', 'salt-syndic'] %}
{% set testing = pillar.get('testing', 'False') %}

{% set on_redhat = os_family == 'RedHat' %}
{% set on_redhat_5 = os_major_release == '5' %}
{% set on_fedora = os_ == 'Fedora' %}

{% if testing == 'True' %}
    {% if on_fedora %}
        {% set install_cmd = 'yum -y --enablerepo=updates-testing install' %}
    {% else %}
        {% set install_cmd = 'yum -y --enablerepo=epel-testing install' %}
    {% endif %}
{% else %}
    {% set install_cmd = 'yum -y install' %}
{% endif %}

{% if on_redhat %}
{% if not on_fedora %}
epel:
  pkg.installed:
    - name: epel-release
{% endif %}

refresh:
  module.run:
    - name: pkg.refresh_db
    {% if not on_fedora %}
    - requires:
      - pkg: epel
    {% endif %}

refresh_backup:
  cmd.run:
    - name: yum -y makecache
    - onfail:
      - module: refresh

# Install salt packages
{% for pkg in pkgs %}
{{ pkg }}:
  cmd.run:
    - name: {{ install_cmd }} {{ pkg }}
    - requires:
      - module: refresh
{% endfor %}
{% endif %}
