#!mako|jinja|yaml
{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

{% set key_timeout = pillar.get('key_timeout', '30') %}
{% set salt_version = salt['pillar.get']('salt_version', '') %}
{% set cloud_profile = salt['pillar.get']('cloud_profile', '') %}
{% set orch_master = salt['pillar.get']('orch_master', '') %}
{% set username = salt['pillar.get']('username', '') %}
{% set wait_for_dns = salt['pillar.get']('wait_for_dns', 'False') %}
{% set install = salt['pillar.get']('install', 'False') %}
{% set install_version = salt['pillar.get']('install_version', '') %}

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

{% if 'python26' in host %}
  {% if 'arch' in host %}
install_python_{{ action }}:
  salt.function:
    - name: cmd.run
    - tgt: {{ orch_master }}
    - arg:
      - salt-ssh {{ host }} -ir "pacman -S python2 --noconfirm"

  {% else %}
install_python_{{ action }}:
  salt.function:
    - name: cmd.run
    - tgt: {{ orch_master }}
    - arg:
      - salt-ssh {{ host }} -ir "mv /var/lib/rpm/Pubkeys /tmp/; rpm --rebuilddb; yum -y install epel-release; yum -y install python26-libs; yum -y install libffi; yum -y install python26"
  {% endif %}
{% endif %}

verify_host_{{ action }}_{{ host }}:
  salt.function:
    - name: cmd.run
    - tgt: {{ orch_master }}
    - arg:
      - salt-ssh {{ host }} -i test.ping
{% endfor %}
{%- endmacro %}


{% macro install_bootstrap(salt_version, install_version, cmd_args, action='None') -%}
test_install_{{ action }}:
  salt.state:
    - tgt: {{ hosts }}
    - tgt_type: list
    - ssh: 'true'
    - sls:
      - test_bootstrap.install_bootstrap
    - pillar:
        install_version: {{ install_version }}
        salt_version: {{ salt_version }}
        cmd_args: {{ cmd_args }}
{%- endmacro %}

{% macro clean_up(action='None') -%}
{% for profile in cloud_profile %}
{% set host = username + profile + rand_name %}

clean_up_known_hosts_{{ action }}:
  salt.function:
    - tgt: {{ orch_master }}
    - name: ssh.rm_known_host
    - arg:
      - root
      - {{ host.lower() }}

{% endfor %}
{%- endmacro %}

{{ create_vm(action='clean') }}

{% set cmd_args = False %}
{% if install == 'git' %}
  {% set cmd_args = 'git v{0}'.format(salt_version) %}
{% endif %}

{{ install_bootstrap(salt_version, install_version, cmd_args, action='install_bootstrap') }}

{{ clean_up(action='clean') }}
{{ destroy_vm(action='clean') }}
