#!mako|jinja|yaml
{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

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
{% set test_rc_pkgs = salt['pillar.get']('test_rc_pkgs', False) %}
{% set hosts = [] %}

<%!
import string
import random
%>
<% random_num = ''.join(random.choice(string.ascii_uppercase) for _ in range(4))
%>

{% set rand_name = <%text>'</%text>${random_num}<%text>'</%text> %}
{% set linux_master = 'qapkgtest-linmaster-' + rand_name %}

{% macro destroy_vm() -%}
{% for profile in cloud_profile %}
{% set host = username + profile + rand_name %}
{% do hosts.append(host) %}
destroy_linux_master_win_minion:
  salt.function:
    - name: cmd.run
    - tgt: {{ orch_master }}
    - arg:     
      - salt-cloud -m /etc/salt/cloud.maps.d/windows-{{ host }}.map -d -y
{% endfor %}
{% endmacro %}


{% macro create_vm(salt_version, action='None') -%}
{% for profile in cloud_profile %}
{% set host = username + profile + rand_name %}
{% do hosts.append(host) %}

setup_win_on_master:
  salt.state:
    - tgt: {{ orch_master }}
    - sls:
      - test_orch.states.setup_windows_on_master
    - concurrent: True
    - pillar:
        salt_version: {{ salt_version }}
        staging: {{ dev }}
        orch_master: {{ orch_master }}
        linux_master: {{ linux_master }}
        test_rc_pkgs: {{ test_rc_pkgs }}
        python3: {{ params.python3 }}
        repo_auth: {{ params.repo_auth }}
        win_arch: {{ params.win_arch }}
        git_user: {{ params.git_user }}
        profile: {{ profile }}
        host: {{ host }}

create_linux_master_win_minion:
  salt.function:
    - name: cmd.run
    - tgt: {{ orch_master }}
    - arg:     
      - salt-cloud -m /etc/salt/cloud.maps.d/windows-{{ host }}.map -y
    - require:
      - salt: setup_win_on_master
    - require_in:
      - salt: add_linux_master_roster
      - salt: sleep_before_verify
      - salt: verify_ssh_hosts

add_linux_master_roster:
  salt.state:
    - tgt: {{ orch_master }}
    - sls:
      - test_orch.states.add_ip_roster
    - concurrent: True
    - pillar:
        salt_version: {{ salt_version }}
        dev: {{ dev }}
        host: {{ host }}
        linux_master_user: {{ params.linux_master_user }}
        linux_master_key: {{ params.linux_master_key }}
        linux_master: {{ linux_master }}

sleep_before_verify:
  salt.function:
    - name: test.sleep
    - tgt: {{ orch_master }}
    - arg:
      - 150

verify_ssh_hosts:
  salt.function:
    - name: cmd.run
    - tgt: {{ orch_master }}
    - arg:
      - salt-ssh {{ linux_master }} -i test.ping

disable_firewall:
  salt.function:
    - name: cmd.run
    - tgt: {{ orch_master }}
    - arg:
      - salt-ssh {{ linux_master }} service.stop firewalld

{% endfor %}
{%- endmacro %} 

{% macro test_run(salt_version, action='None', upgrade_val='False') -%}
test_run_{{ action }}:
  salt.state:
    - tgt: {{ linux_master }}
    - tgt_type: glob
    - ssh: 'true'
    - sls:
      - test_run.windows
    - pillar:
        salt_version: {{ salt_version }}
        dev: {{ dev }}
{%- endmacro %}

{% macro upgrade_salt(salt_version, action='None', upgrade_val='False') -%}
upgrade_salt_{{ action }}:
  salt.state:
    - tgt: {{ linux_master }}
    - tgt_type: glob
    - ssh: 'true'
    - sls:
      - test_orch.states.upgrade_win_minion
    - pillar:
        salt_version: {{ salt_version }}
        dev: {{ dev }}
        win_arch: {{ params.win_arch }}
        python3: {{ params.python3 }}
        repo_auth: {{ params.repo_auth }}
{%- endmacro %}

{% macro clean_up(action='None') -%}
{% for profile in cloud_profile %}
{% set host = username + profile + rand_name %}
clean_up_known_hosts_{{ action }}:
  salt.state:
    - tgt: {{ orch_master }}
    - tgt_type: list
    - sls:
      - test_orch.states.rm_known_hosts
    - pillar:
        host: {{ linux_master }}

clean_ssh_roster_{{ action }}:
  salt.function:
    - tgt: {{ orch_master }}
    - name: roster.remove
    - arg:
      - /etc/salt/roster
      - {{ linux_master }}

{% endfor %}
{%- endmacro %}

{% if clean %}
{{ create_vm(salt_version, action='clean') }}
{{ test_run(salt_version, action='clean') }}
{{ clean_up(action='clean') }}
{{ destroy_vm() }}
{% endif %}

{% if upgrade %}
{{ create_vm(upgrade_salt_version, action='upgrade') }}
{{ test_run(upgrade_salt_version, action='preupgrade') }}
{{ upgrade_salt(salt_version, action='upgrade') }}
{{ test_run(salt_version, action='after_upgrade') }}
{{ clean_up(action='upgrade') }}
{{ destroy_vm() }}
{% endif %}
