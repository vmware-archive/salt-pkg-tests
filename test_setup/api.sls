{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}
{% set api_services = ['salt-api', 'salt-master'] %}

{{ params.api_user }}:
  user.present:
    - password: $6$pvWzdxid$dnwiqGjskc1lF0h8.3yA0PA.RVmKMEVtuOgcWc4o7iRZluB1ZXUFHmtzV/Mtbgq7.Wq/TbzAqhuyYgV0Obcqz0

api_config:
  file.managed:
    - name: {{ params.api_config }}
    - contents: |
        rest_cherrypy:
          port: 8000
          disable_ssl: True
          debug: True
          host: 0.0.0.0
          webhook_url: /hook
          webhook_disable_auth: True
        external_auth:
          pam:
            {{ params.api_user }}:
              - .*
              - '@runner'
              - '@wheel'
              - '@jobs'
            root:
              - .*
              - '@runner'
              - '@wheel'
              - '@jobs'

{% for service in api_services %}
{{ service }}_running:
  service.running:
    - name: {{ service }}
    - watch:
      - file: api_config
{% endfor %}
