{% set tmp_docker_dir = '/tmp/docker/' %}
{% set salt_version = pillar['salt_version'] %}
{% set verify_salt = 'salt-master --version; salt-minion --version; salt-ssh --version; salt-syndic --version; salt-cloud --version; salt-api --version;' %}
{% set staging = True if pillar['staging'] == True else False %}

setup_install_inst:
  cmd.script:
    - name: salt://test_download/download.py
    - template: jinja
    - context:
        staging: {{ staging }}


{% for os, args in pillar['os'].iteritems() %}
{% for install_type in pillar['install_type'] %}

{# directory values #}
{% set dockerfile_dir = tmp_docker_dir + os + '/' + install_type + '/' %}
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

{{ state_id }}add_dockerfile:
  file.managed:
    - name: {{ dockerfile }}
    - source: salt://test_download/Dockerfile
    - makedirs: True
    - template: jinja
    - context:
        os: {{ os }}
        osflavor: {{ osflavor }}
        distro: {{ distro }}
        staging: {{ staging }}
        tag: {{ tag }}

{{ state_id }}build:
  docker.built:
    - name: {{ image_name }}
    - tag: {{ image_tag }}
    - path: {{ dockerfile_dir }}
    - force: True

{{ state_id }}run_container:
  cmd.run:
    - name: docker run -i {{ image_name }}:{{ image_tag }} /bin/bash -c "{{ verify_salt }}"
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
