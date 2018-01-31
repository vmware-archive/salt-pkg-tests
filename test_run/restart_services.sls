{% set restart_services = ['salt-api'] %}

{% for service in restart_services %}
restart_{{ service }}:
  module.run:
    - name: service.restart
    - m_name: {{ service }}

sleep_wait_for_restart_{{ service }}:
  module.run:
    - name: test.sleep
    - length: 10
{% endfor %}
