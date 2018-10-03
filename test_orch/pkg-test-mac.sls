#!mako|jinja|yaml
{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

{% set key_timeout = pillar.get('key_timeout', '30') %}
{% set salt_version = salt['pillar.get']('salt_version', '') %}
{% set upgrade_salt_version = salt['pillar.get']('upgrade_salt_version', '') %}
{% set repo_pkg = salt['pillar.get']('repo_pkg', '') %}
{% set latest = salt['pillar.get']('latest', '') %}
{% set dev = salt['pillar.get']('dev', '') %}
{% set cloud_profile = salt['pillar.get']('cloud_profile', '') %}
{% set orch_master = salt['pillar.get']('orch_master', '') %}
{% set username = salt['pillar.get']('username', '') %}
{% set upgrade = salt['pillar.get']('upgrade', '') %}
{% set clean = salt['pillar.get']('clean', '') %}
{% set repo = salt['pillar.get']('repo', '') %}
{% set repo_user = salt['pillar.get']('repo_user', '') %}
{% set repo_passwd = salt['pillar.get']('repo_passwd', '') %}
{% set wait_for_dns = salt['pillar.get']('wait_for_dns', 'False') %}
{% set mac_min_user = salt['pillar.get']('mac_min_user', '') %}
{% set mac_min_passwd = salt['pillar.get']('mac_min_passwd', '') %}
{% set master_host = 'qapkg-linux-master-' %}
{% set master_profile = salt['pillar.get']('master_profile', '') %}
{% set bootstrap_repo = salt['pillar.get']('bootstrap_repo', '') %}
{% set parallels_master = salt['pillar.get']('parallels_master') %}


<%!
import string
import random
%>
<% random_num = ''.join(random.choice(string.ascii_uppercase) for _ in range(4))
%>

{% set rand_name = <%text>'</%text>${random_num}<%text>'</%text> %}

{% set hosts = [] %}
{% set master_host = master_host + rand_name %}

{% macro destroy_vm(action='None') -%}
{% for profile in cloud_profile %}
{% set host = username + profile + rand_name %}
{% do hosts.append(host) %}

stop_{{ host }}:
  salt.function:
    - name: cmd.run
    - tgt: {{ parallels_master }}
    - ssh: 'true'
    - arg:
      - /opt/salt/bin/salt-call --local parallels.stop {{ host }} runas=parallels

delete_{{ host }}:
  salt.function:
    - name: cmd.run
    - tgt: {{ parallels_master }}
    - ssh: 'true'
    - arg:
      - /opt/salt/bin/salt-call --local parallels.delete {{ host }} runas=parallels

destroy_master_{{ host }}:
  salt.function:
    - name: salt_cluster.destroy_node
    - tgt: {{ orch_master }}
    - arg:
      - {{ master_host }}

{% endfor %}
{% endmacro %}

{% macro create_vm(action='None') -%}
accept_ssh_key_{{ action }}:
  salt.function:
    - name: cmd.run
    - tgt: {{ orch_master }}
    - arg:
      - salt-ssh "{{ parallels_master }}" -i test.ping
{% for profile in cloud_profile %}
{% set host = username + profile + rand_name %}
{% do hosts.append(host) %}
{% set py = '-py2' if not params.python3 else '-py3' %}
{% set profile = profile + py %}
create_{{ action }}_linux_master:
  salt.function:
    - name: salt_cluster.create_node
    - tgt: {{ orch_master }}
    - arg:
      - {{ master_host }}
      - {{ master_profile }}
    - require_in:
      - salt: clone_{{ action }}_{{ host }}
      - salt: start_{{ action }}_{{ host }}
      - salt: sleep_{{ action }}_{{ host }}
      - salt: add_ip_{{ host }}_roster
      - salt: verify_host_{{ action }}_{{ host }}

clone_{{ action }}_{{ host }}:
  salt.function:
    - name: cmd.run
    - tgt: {{ parallels_master }}
    - ssh: 'true'
    - arg:
      - /opt/salt/bin/salt-call --local parallels.clone {{ profile }} {{ host }} linked=True runas=parallels -ldebug

start_{{ action }}_{{ host }}:
  salt.function:
    - name: cmd.run
    - tgt: {{ parallels_master }}
    - ssh: 'true'
    - arg:
      - /opt/salt/bin/salt-call --local parallels.start {{ host }} runas=parallels

sleep_{{ action }}_{{ host }}:
  salt.function:
    - name: test.sleep
    - tgt: {{ orch_master }}
    - arg:
      - 200

add_ip_{{ host }}_roster:
  salt.state:
    - tgt: {{ orch_master }}
    - tgt_type: list
    - concurrent: True
    - sls:
      - test_orch.states.mac_ip
    - timeout: 200
    - pillar:
        host: {{ host }}
        mac_min_user: {{ mac_min_user }}
        mac_min_passwd: {{ mac_min_passwd }}
        parallels_master: {{ parallels_master }}

verify_host_{{ action }}_{{ host }}:
  salt.function:
    - name: cmd.run
    - tgt: {{ orch_master }}
    - arg:
      - salt-ssh -L "{{ master_host }},{{ host }}" -i test.ping

{% endfor %}
{%- endmacro %}

{% macro setup_salt(salt_version, action='None', upgrade_val='False') -%}
bootstrap_master_{{ action }}:
  salt.state:
    - tgt: {{ master_host }}
    - tgt_type: list
    - ssh: 'true'
    - concurrent: True
    - sls:
      - test_install.bootstrap
    - pillar:
        salt_version: {{ salt_version }}
        bootstrap_repo: {{ bootstrap_repo }}
    - require_in:
      - salt: test_install_{{ action }}
      - salt: disable_firewalld_{{ hosts[0] }}_{{ action }}
      - salt: wait_for_firewall_{{ hosts }}_{{ action }}
      - salt: accept_{{ hosts[0] }}_{{ action }}
      - salt: sleep_after_accept_{{ hosts[0] }}_{{ action }}
      - salt: test_run_{{ action }}

test_install_{{ action }}:
  salt.state:
    - tgt: {{ hosts }}
    - tgt_type: list
    - ssh: 'true'
    - sls:
      - test_install.saltstack
    - pillar:
        minion_only: True
        salt_version: {{ salt_version }}
        dev: {{ dev }}
        latest: {{ latest }}
        upgrade: {{ upgrade_val }}
        minion_id: {{ hosts[0] }}
        test_os: 'MacOS'
        repo_user: {{ repo_user }}
        repo_passwd: {{ repo_passwd }}
        master_host: {{ master_host }}
        python3: {{ params.python3 }}
    - require_in:
      - salt: disable_firewalld_{{ hosts[0] }}_{{ action }}
      - salt: wait_for_firewall_{{ hosts }}_{{ action }}
      - salt: accept_{{ hosts[0] }}_{{ action }}
      - salt: sleep_after_accept_{{ hosts[0] }}_{{ action }}
      - salt: test_run_{{ action }}

{% if upgrade_val == 'False' %}
test_setup_{{ action }}:
  salt.state:
    - tgt: {{ orch_master }}
    - sls:
      - test_setup.minion_only.macosx
    - concurrent: True
    - pillar:
        salt_version: {{ salt_version }}
        minion_only: True
        test_os: 'MacOS'
        host: {{ hosts[0] }}
        minion_id: {{ hosts[0] }}
        dev: {{ dev }}
        key_timeout: {{ key_timeout }}
        master_host: {{ master_host }}
        python3: {{ params.python3 }}
    - require:
      - salt: test_install_{{ action }}
    - require_in:
      - salt: test_run_{{ action }}

sleep_{{ hosts }}:
  salt.function:
    - name: test.sleep
    - tgt: {{ orch_master }}
    - arg:
      - 45

{% endif %}

disable_firewalld_{{ hosts[0] }}_{{ action }}:
  salt.function:
    - name: service.stop
    - tgt: {{ master_host }}
    - ssh: 'true'
    - arg:
      - firewalld

wait_for_firewall_{{ hosts }}_{{ action }}:
  salt.function:
    - name: test.sleep
    - tgt: {{ orch_master }}
    - arg:
      - 45

accept_{{ hosts[0] }}_{{ action }}:
  salt.function:
    - name: cmd.run
    - tgt: {{ master_host }}
    - ssh: 'true'
    - arg:
      - salt-key -a {{ hosts[0] }} -y

sleep_after_accept_{{ hosts[0] }}_{{ action }}:
  salt.function:
    - name: test.sleep
    - tgt: {{ orch_master }}
    - arg:
      - 15

test_run_{{ action }}:
  salt.state:
    - tgt: {{ master_host }}
    - tgt_type: list
    - ssh: 'true'
    - sls:
      - test_run.minion_only.macosx
    - pillar:
        salt_version: {{ salt_version }}
        dev: {{ dev }}
        repo_user: {{ repo_user }}
        repo_passwd: {{ repo_passwd }}
        upgrade: {{ upgrade_val }}
        minion_only: True
        test_os: 'MacOS'
        minion_id: {{ hosts[0] }}
        python3: {{ params.python3 }}
{%- endmacro %}

{% macro clean_up(action='None') -%}
{% for profile in cloud_profile %}
{% set host = username + profile + rand_name %}

{% for ssh_host in [host, master_host] %}
clean_up_known_hosts_{{ ssh_host }}_{{ action }}:
  salt.function:
    - tgt: {{ orch_master }}
    - name: ssh.rm_known_host
    - arg:
      - root
      - {{ ssh_host.lower() }}

clean_ssh_roster_{{ ssh_host }}_{{ action }}:
  salt.function:
    - tgt: {{ orch_master }}
    - name: roster.remove
    - arg:
      - /etc/salt/roster
      - {{ ssh_host }}

{% endfor %}
{% endfor %}
{%- endmacro %}

{% if clean %}
{{ create_vm(action='clean') }}
{{ setup_salt(salt_version, action='clean') }}
{{ clean_up(action='clean') }}
{{ destroy_vm(action='clean') }}
{% endif %}

{% if upgrade %}
{{ create_vm(action='upgrade') }}
{{ setup_salt(upgrade_salt_version, action='preupgrade') }}
{{ setup_salt(salt_version, action='upgrade', upgrade_val='True') }}
{{ clean_up(action='upgrade') }}
{{ destroy_vm(action='upgrade') }}
{% endif %}
