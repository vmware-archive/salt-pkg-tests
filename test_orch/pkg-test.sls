#!mako|jinja|yaml
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
{% set wait_for_dns = salt['pillar.get']('wait_for_dns', 'False') %}

<%!
import string
import random
%>
<% random_num = ''.join(random.choice(string.ascii_uppercase) for _ in range(4))
%>

{% set rand_name = <%text>'</%text>${random_num}<%text>'</%text> %}

{% set hosts = [] %}

{% macro destroy_vm(action='None') -%}
{% for profile in cloud_profile %}
{% set host = username + profile + rand_name %}
{% do hosts.append(host) %}

destroy_{{ host }}:
  salt.function:
    - name: salt_cluster.destroy_node
    - tgt: {{ orch_master }}
    - arg:
      - {{ host }}

{% endfor %}
{% endmacro %}

{% macro create_vm(action='None') -%}
{% for profile in cloud_profile %}
{% set host = username + profile + rand_name %}
{% do hosts.append(host) %}
create_{{ action }}_{{ host }}:
  salt.function:
    - name: salt_cluster.create_node
    - tgt: {{ orch_master }}
    - arg:
      - {{ host }}
      - {{ profile }}

{% if wait_for_dns %}
wait_for_dns:
  salt.state:
    - tgt: {{ orch_master }}
    - tgt_type: list
    - concurrent: True
    - sls:
      - test_orch.states.wait_for_dns
    - timeout: 200
    - pillar:
        hostname: {{ host }}
    - require:
      - salt: create_{{ action }}_{{ host }}
    - require_in:
      - salt: verify_host_{{ action }}_{{ host }}
{% else %}
sleep_{{ action }}_{{ host }}:
  salt.function:
    - name: test.sleep
    - tgt: {{ orch_master }}
    - arg:
      - 240
    - require:
      - salt: create_{{ action }}_{{ host }}
    - require_in:
      - salt: verify_host_{{ action }}_{{ host }}
{% endif %}

{% if '5' in host %}
install_python_{{ action }}:
  salt.function:
    - name: cmd.run
    - tgt: {{ orch_master }}
    - arg:
      - salt-ssh {{ host }} -ir "mv /var/lib/rpm/Pubkeys /tmp/; rpm --rebuilddb; yum -y install epel-release; yum -y install python26-libs; yum -y install libffi; yum -y install python26"
{% endif %}

verify_host_{{ action }}_{{ host }}:
  salt.function:
    - name: cmd.run
    - tgt: {{ orch_master }}
    - arg:
      - salt-ssh {{ host }} -i test.ping
{% endfor %}
{%- endmacro %}


{% macro setup_salt(salt_version, action='None', upgrade_val='False') -%}
test_install_{{ action }}:
  salt.state:
    - tgt: {{ hosts }}
    - tgt_type: list
    - ssh: 'true'
{% if 'saltstack' in repo %}
    - sls:
      - test_install.saltstack
{% endif %}
{% if 'community' in repo %}
    - sls:
      - test_install.community
{% endif %}
    - pillar:
        salt_version: {{ salt_version }}
        dev: {{ dev }}
        latest: {{ latest }}
        repo_pkg: {{ repo_pkg }}
        upgrade: {{ upgrade_val }}

{% if upgrade_val == 'False' %}
test_setup_{{ action }}:
  salt.state:
    - tgt: {{ hosts }}
    - tgt_type: list
    - ssh: 'true'
    - sls:
      - test_setup
    - pillar:
        salt_version: {{ salt_version }}
        dev: {{ dev }}
    - require:
      - salt: test_install_{{ action }}
    - require_in:
      - salt: test_run_{{ action }}
{% endif %}

test_run_{{ action }}:
  salt.state:
    - tgt: {{ hosts }}
    - tgt_type: list
    - ssh: 'true'
    - sls:
      - test_run
    - pillar:
        salt_version: {{ salt_version }}
        dev: {{ dev }}
{%- endmacro %}

{% if clean %}
{{ create_vm(action='clean') }}
{{ setup_salt(salt_version, action='clean') }}
{{ destroy_vm(action='clean') }}
{% endif %}

{% if upgrade %}
{{ create_vm(action='upgrade') }}
{{ setup_salt(upgrade_salt_version, action='preupgrade') }}
{{ setup_salt(salt_version, action='upgrade', upgrade_val='True') }}
{{ destroy_vm(action='upgrade') }}
{% endif %}
