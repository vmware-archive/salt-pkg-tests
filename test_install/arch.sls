{% set transport = pillar.get('transport', 'zmq') %}
{% set testing = pillar.get('testing', 'False') %}
{% set pkgs = ['salt-zmq'] %}
{% set install_cmd = 'pacman -Syu ' %}

{% if transport == 'raet' %}
    {% set pkgs = ['salt-raet'] %}
{% endif %}

{% if testing == 'True' %}

    {% set install_cmd = 'pacman -Syu testing/' %}

# Enable the testing repo in /etc/pacman.conf
enable_arch_testing_mirror:
  file.append:
    - name: /etc/pacman.conf
    - text:
      - [testing]
      - Include = /etc/pacman.d/mirrorlist

{% endif %}

# Install salt packages
{% for pkg in pkgs %}
{{ pkg }}:
  cmd.run:
    - name: {{ install_cmd }}{{ pkg }}
{% endfor %}
