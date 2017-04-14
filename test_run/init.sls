{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

{% set branch = params.salt_version.rsplit('.', 1)[0] %}
{% set srpms_pkg = 'salt-{0}-1.el{2}.src.rpm'.format(params.salt_version, params.repo_pkg_version, params.os_major_release) %}
{% set srpms_test = 'https://repo.saltstack.com/{0}/yum/redhat/{1}/x86_64/archive/{2}/SRPMS/{3}'.format(params.dev, params.os_major_release, params.salt_version, srpms_pkg )  %}
{% set srpms_run = '/root/salt-{0}-1.el{2}.src.rpm'.format(params.salt_version, params.repo_pkg_version, params.os_major_release) %}
{% set services = ['salt-master', 'salt-minion', 'salt-syndic', 'salt-api'] %}

# The top level cmd.run statements here are instructions to the salt-ssh minion,
# not the salt being tested
{% if params.on_smartos %}
{% set update_path = salt['environ.get']('PATH', '') + ':/opt/salt/bin/' %}
add_saltkey_path:
   environ.setenv:
     - name: PATH
     - value: {{ update_path }}
     - update_minion: True
{% endif %}

utils_installed:
  cmd.run:
    - names:
      {% for util in params.utils %}
      - '{{ util }} --help 1> /dev/null ; ( exit $? )'
      {% endfor %}

key:
  cmd.run:
    - name: salt-key -L

versions:
  cmd.run:
    - names:
      - salt --versions-report
      - salt {{ params.minion_id }} test.versions_report

compare_versions:
  cmd.script:
    - name: /tmp/check_cmd_returns.py
    - source: salt://test_run/files/check_cmd_returns.py
    - args: "-m {{ params.minion_id }} -v {{ params.salt_version }}"

grains:
  cmd.run:
    - names:
      - salt {{ params.minion_id }} grains.item os
      - salt {{ params.minion_id }} grains.item pythonversion
      - salt {{ params.minion_id }} grains.setval key val

pillar:
  cmd.run:
    - names:
      - salt {{ params.minion_id }} pillar.items

output:
  cmd.run:
    - names:
      - salt --output=yaml {{ params.minion_id }} test.fib 7
      - salt --output=json {{ params.minion_id }} test.fib 7

exec:
  cmd.run:
    - names:
      - salt {{ params.minion_id }} cmd.run 'ls -lah /'
      - salt {{ params.minion_id }} user.list_users
      - salt {{ params.minion_id }} network.arp

{% set exists = salt['cmd.run']('pidof systemd') %}
{% if exists %}
systemd_config_check:
  cmd.script:
    - name: systemd_check
    - source: salt://test_run/files/systemd_script.sh
{% endif %}

state_file:
  file.managed:
    - name: {{ params.file_roots }}/states.sls
    - makedirs: True
    - contents: |
        update:
          pkg.installed:
            - name: bash
        salt_dude:
          user.present:
            - name: dude
            - fullname: Salt Dude

state:
  cmd.run:
    - names:
      - salt {{ params.minion_id }} state.sls states
    - require:
      - file: state_file

salt-call:
  cmd.run:
    - names:
      - salt-call --local sys.doc none
      - salt-call --local state.apply states
      - salt-call --local sys.doc aliases.list_aliases

{% if params.os_family == 'RedHat' %}
check_srpms::
  cmd.run:
    - name: wget {{ srpms_test }}; rpm -ihv {{ srpms_run }}
{% endif %}

{% for service in services %}
check_services_enabled_{{ service }}:
  service.enabled:
    - name: {{ service }}

run_if_changes_{{ service }}:
  cmd.run:
    - name: failtest service is enabled
    - onchanges:
      - service: check_services_enabled_{{ service }}
{% endfor %}

