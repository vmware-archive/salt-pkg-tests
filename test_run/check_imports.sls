{% import 'params.jinja' as params %}

{% set salt_dirs = ['templates', 'platform', 'cli', 'executors', 'config', 'wheel', 'netapi', 'cache', 'proxy', 'transport', 'metaproxy', 'modules', 'tokens', 'matchers', 'acl', 'auth', 'log', 'engines', 'client', 'returners', 'runners', 'tops', 'output', 'daemons', 'thorium', 'renderers', 'states', 'cloud', 'roster', 'beacons', 'pillar', 'spm', 'utils', 'sdb', 'fileserver', 'defaults', 'ext', 'queues', 'grains', 'serializers'] %}

{% for dir in salt_dirs %}
check_{{ dir }}:
  cmd.run:
    - name: {{ params.python_version }} -c "import salt.{{ dir }}"
{% endfor %}

