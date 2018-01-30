{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

{% set pkg_name = 'salt-{0}-py{1}-x86_64.pkg'.format(params.salt_version, params.python_major_version) %}
{% set pkg_url = 'https://{0}repo.saltstack.com/{1}osx/{2}'.format(params.repo_auth, params.dev, pkg_name) %}
{% set pkg_url_hash = '{0}.md5'.format(pkg_url) %}
{% set pkg_location = '/tmp/{0}'.format(pkg_name) %}

get_mac_pkg:
  file.managed:
    - name: {{ pkg_location }}
    - source: {{ pkg_url }}
    - skip_verify: True

install_mac:
  cmd.run:
    - name: installer -pkg {{ pkg_location }} -target /
