{% set salt_version = pillar['salt_version'] %}
{% set verify_salt = 'salt-master --version; salt-minion --version; salt-ssh --version; salt-syndic --version; salt-cloud --version; salt-api --version;' %}
{% set staging = True if pillar['staging'] == True else False %}
{% set salt_branch = salt_version.rsplit('.', 1)[0] %}
{% set rand_dir = salt['random.get_str']('7') %}
{% set tmp_docker_dir = '/tmp/docker/' ~ rand_dir %}

make_tmp_dir:
  file.directory:
    - name: {{ tmp_docker_dir }}
    - makedirs: True

setup_install_inst:
  cmd.script:
    - name: {{ tmp_docker_dir }}/add_install_inst.py
    - source: salt://test_download/download.py
    - template: jinja
    - args: "-b {{ salt_branch }}"
    - context:
        staging: {{ staging }}
        rand_dir: {{ rand_dir }}

{% for os, args in pillar['os'].iteritems() %}
{% for install_type in pillar['install_type'] %}

{# directory values #}
{% set dockerfile_dir = tmp_docker_dir  ~ '/' ~ salt_branch ~ '/' + os + '/' + install_type + '/' %}
{% set dockerfile = dockerfile_dir + 'Dockerfile' %}

{# os values #}
{% set os_version = args['os_version'] %}
{% set tag = args['tag'] %}
{% set distro = args['distro'] %}
{% set state_id = os + os_version + install_type %}
{% set osflavor = args['osflavor'] %}

{# repo urls and other #}
{% if os == 'windows' %} {% set pkg_name = 'Salt-Minion-{0}-{1}-Setup.exe'.format(salt_version, 'AMD64') %}
{% set md5_name = pkg_name + '.md5' %}
{% set staging = '/staging/' if pillar['staging'] == True else '' %}
{% set repo_url = 'https://repo.saltstack.com{0}windows/'.format(staging) %}
{% set pkg_url = repo_url + pkg_name %}
{% set md5_url = repo_url + md5_name %}
{% elif os == 'macosx' %}
{% set pkg_name = 'salt-{0}-{1}.pkg'.format(salt_version, 'x86_64') %}
{% set md5_name = pkg_name + '.md5' %}
{% set repo_url = 'https://repo.saltstack.com{0}osx/'.format(staging) %}
{% set pkg_url = repo_url + pkg_name %}
{% set md5_url = repo_url + md5_name %}
{% endif %}

{# docker images-tag values #}
{% set image_name = 'testing-' + os + os_version %}
{% set image_tag = os + '-' + install_type + os_version %}
{% set test_docker = True if args['test_with_docker'] == True else False %}

{% if test_docker %}

{{ state_id }}add_version_script:
  file.managed:
    - name: {{ dockerfile_dir }}check_cmd_returns.py
    - source: salt://test_run/files/check_cmd_returns.py

{{ state_id }}add_dockerfile:
  file.managed:
    - name: {{ dockerfile }}
    - source: salt://test_download/Dockerfile
    - template: jinja
    - context:
        os: {{ os }}
        osflavor: {{ osflavor }}
        distro: {{ distro }}
        staging: {{ staging }}
        tag: {{ tag }}

{% if staging %}
{{ state_id }}add_staging_yum:
  file.replace:
    - name: {{ dockerfile_dir }}/install_salt.sh
    - pattern: com/yum
    - repl: com/staging/yum
{{ state_id }}add_staging_apt:
  file.replace:
    - name: {{ dockerfile_dir }}/install_salt.sh
    - pattern: com/apt
    - repl: com/staging/apt
{% endif %}

{{ state_id }}build:
  docker.built:
    - name: {{ image_name }}
    - tag: {{ image_tag }}
    - path: {{ dockerfile_dir }}
    - force: True

{{ state_id }}run_container:
  cmd.run:
    - name: docker run -i {{ image_name }}:{{ image_tag }} /bin/bash -c "{{ verify_salt }}"

{{ state_id }}compare_versions:
  cmd.run:
    - name: docker run -i {{ image_name }}:{{ image_tag }} python /tmp/check_cmd_returns.py -a -v {{ salt_version }}

{% else %}

download_{{ state_id }}{{ osflavor }}_pkg:
  file.managed:
    - name: /tmp/pkgtest/{{ pkg_name }}
    - source: {{ pkg_url }}
    - source_hash: {{ md5_url }}
    - makedirs: True

{% endif %}
{% endfor %}
{% endfor %}
