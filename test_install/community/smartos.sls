{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

{% set pkg_ver = '2018Q1' %}
{% set pkg_arch = 'x86_64' %}
{% set gpg_keyname = 'pbd-signature-{0}.key'.format(pkg_ver) %}
{% set gpg_key_location = '/tmp/' + gpg_keyname %}
{% set gpg_keyring = '/opt/local/etc/gnupg/pkgsrc.gpg' %}

get_key:
  file.managed:
    - name: {{ gpg_key_location }}
    - source: http://pkg.blackdot.be/{{ gpg_keyname }}
    - skip_verify: True

import_gpg_key:
  cmd.run:
    - name: gpg --no-default-keyring --keyring {{ gpg_keyring }} --import {{ gpg_key_location }}

add_repo:
  file.append:
    - name: /opt/local/etc/pkgin/repositories.conf
    - text: |
        http://pkg.blackdot.be/packages/{{ pkg_ver }}/{{ pkg_arch }}/All

refresh_repo:
  cmd.run:
    - name: pkgin -fy up

install_salt:
  cmd.run:
    - name: pkgin -y in salt-{{ params.salt_version }}
