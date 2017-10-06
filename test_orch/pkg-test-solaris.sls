#!mako|jinja|yaml
{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

<%!
import string
import random
%>
<% random_num = ''.join(random.choice(string.ascii_uppercase) for _ in range(4))
%>

{% set rand_name = <%text>'</%text>${random_num}<%text>'</%text> %}


{% macro create_vm(action='None') -%}
{% for profile in params.cloud_profile %}
{% set host = params.username + profile + rand_name %}
{% do params.hosts.append(host) %}
{% set zone_profile = host + 'profile' %}
{% set zone_template = host + 'template' %}
{% set solaris_master = host + '-master' %}

add_roster_file:
  salt.state:
    - tgt: {{ params.orch_master }}
    - tgt_type: list
    - concurrent: True
    - sls:
      - test_orch.states.add_solaris_roster
    - timeout: 200
    - pillar:
        solaris_master: {{ solaris_master }}
        solarism_user: {{ params.solarism_user }}
        solarism_passwd: {{ params.solarism_passwd }}
        solarism_host: {{ params.solarism_host }}

add_zone_profile:
  salt.state:
    - tgt: {{ solaris_master }}
    - tgt_type: list
    - concurrent: True
    - sls:
      - test_orch.states.add_zone_profile
    - ssh: True
    - timeout: 200
    - pillar:
        zone_profile: {{ zone_profile }}
        host: {{ host }}

add_zone_template:
  salt.state:
    - tgt: {{ solaris_master }}
    - tgt_type: list
    - concurrent: True
    - sls:
      - test_orch.states.add_zone_template
    - ssh: True
    - timeout: 200
    - pillar:
        zone_template: {{ zone_template }}
        host: {{ host }}
        zone_pkgusr_passwd: {{ params.zone_pkgusr_passwd }}
        zone_root_passwd: {{ params.zone_root_passwd }}

configure_zone:
  salt.function:
    - name: cmd.run
    - tgt: {{ solaris_master }}
    - tgt_type: list
    - ssh: True
    - arg:
      - zonecfg -z {{ host }} -f /tmp/{{ zone_profile }}

install_zone:
  salt.function:
    - name: cmd.run
    - tgt: {{ solaris_master }}
    - tgt_type: list
    - ssh: True
    - arg:
      - zoneadm -z {{ host }} clone -c /tmp/{{ zone_template }}.xml testzone

boot_zone:
  salt.function:
    - name: cmd.run
    - tgt: {{ solaris_master }}
    - tgt_type: list
    - ssh: True
    - arg:
      - zoneadm -z {{ host }} boot

sleep_while_zone_boots:
  salt.function:
    - name: test.sleep
    - tgt: {{ params.orch_master }}
    - arg:
      - 200

add_solaris_minion_to_roster:
  salt.state:
    - tgt: {{ params.orch_master }}
    - tgt_type: list
    - concurrent: True
    - sls:
      - test_orch.states.get_solaris_min_ip
    - timeout: 200
    - pillar:
        solarismin_user: {{ params.solarismin_user }}
        solarismin_passwd: {{ params.solarismin_passwd }}
        host: {{ host }}

verify_solaris_minion:
  salt.function:
    - name: cmd.run
    - tgt: {{ orch_master }}
    - arg:
      - salt-ssh {{ host }} -i test.ping
{% endfor %}
{%- endmacro %}

{% macro destroy_vm(action='None') -%}
{% for profile in params.cloud_profile %}
{% set host = params.username + profile + rand_name %}
{% do params.hosts.append(host) %}
{% set solaris_master = host + '-master' %}

shutdown_zone:
  salt.function:
    - name: cmd.run
    - tgt: {{ solaris_master }}
    - tgt_type: list
    - ssh: True
    - arg:
      - zoneadm -z {{ host }} shutdown

remove_zone_filesystem:
  salt.function:
    - name: cmd.run
    - tgt: {{ solaris_master }}
    - tgt_type: list
    - ssh: True
    - arg:
      - zoneadm -z {{ host }} uninstall -F

remove_zone_configuration:
  salt.function:
    - name: cmd.run
    - tgt: {{ solaris_master }}
    - tgt_type: list
    - ssh: True
    - arg:
      - zonecfg -z {{ host }} delete -F
{% endfor %}
{% endmacro %}


{% if params.clean %}
{{ create_vm(action='clean') }}
{#{{ destroy_vm(action='clean') }}#}
{% endif %}
