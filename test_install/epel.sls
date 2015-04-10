{% set os = salt['grains.get']('os', '') %}
{% set pkgs = ['salt-master', 'salt-minion', 'salt-api', 'salt-cloud', 'salt-ssh', 'salt-syndic'] %}
{% set testing = pillar.get('testing', 'False') %}

{% if testing == 'True' %}
    {% if os == 'Fedora' %}
        {% set install_cmd = 'yum -y --enablerepo=updates-testing install' %}
    {% else %}
        {% set install_cmd = 'yum -y --enablerepo=epel-testing install' %}
    {% endif %}
{% else %}
    {% set install_cmd = 'yum -y install' %}
{% endif %}

{% if os != 'Fedora' %}
# Install Epel
epel:
  cmd.run:
    - name: yum -y install epel-release
{% endif %}

# Install salt packages
{% for pkg in pkgs %}
{{ pkg }}:
  cmd.run:
    - name: {{ install_cmd }} {{ pkg }}
{% endfor %}
