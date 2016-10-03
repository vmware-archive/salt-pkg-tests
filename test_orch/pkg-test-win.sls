{% set salt_version = salt['pillar.get']('salt_version', '') %}
{% set upgrade_salt_version = salt['pillar.get']('upgrade_salt_version', '') %}
{% set repo_pkg = salt['pillar.get']('repo_pkg', '') %}
{% set latest = salt['pillar.get']('latest', '') %}
{% set dev = salt['pillar.get']('dev', '') %}
{% set dev = dev + '/' if dev else '' %}
{% set cloud_profile = salt['pillar.get']('cloud_profile', '') %}
{% set orch_master = salt['pillar.get']('orch_master', '') %}
{% set username = salt['pillar.get']('username', '') %}
{% set upgrade = salt['pillar.get']('upgrade', '') %}
{% set clean = salt['pillar.get']('clean', '') %}
{% set hosts = [] %}

{% macro destroy_vm() -%}
destroy_linux_master_win_minion:
  salt.function:
    - name: cmd.run
    - tgt: {{ orch_master }}
    - arg:     
      - salt-cloud -m /etc/salt/cloud.maps.d/windows.map -d -y
{% endmacro %}


{% macro create_vm(action='None') -%}
setup_win_on_master:
  salt.state:
    - tgt: {{ orch_master }}
    - sls:
      - test_orch.states.setup_windows_on_master
    - pillar:
        salt_version: {{ salt_version }}
        dev: {{ dev }}
        orch_master: {{ orch_master }}
    - require_in:
      - salt: create_linux_master_win_minion
      - salt: sleep_before_verify
      - salt: verify_ssh_hosts

create_linux_master_win_minion:
  salt.function:
    - name: cmd.run
    - tgt: {{ orch_master }}
    - arg:     
      - salt-cloud -m /etc/salt/cloud.maps.d/windows.map -y

sleep_before_verify:
  salt.function:
    - name: test.sleep
    - tgt: {{ orch_master }}
    - arg:
      - 120

verify_ssh_hosts:
  salt.function:
    - name: cmd.run
    - tgt: {{ orch_master }}
    - arg:
      - salt-ssh '*' -i test.ping
{%- endmacro %} 

{% macro setup_salt(salt_version, action='None', upgrade_val='False') -%}
test_run_{{ action }}:
  salt.state:
    - tgt: '*master*' 
    - tgt_type: glob
    - ssh: 'true'
    - sls:
      - test_run.windows
    - pillar:
        salt_version: {{ salt_version }}
        dev: {{ dev }}
{%- endmacro %}

{% if clean %}
{{ create_vm(action='clean') }}
{{ setup_salt(salt_version, action='clean') }}
{{ destroy_vm() }}
{% endif %}
