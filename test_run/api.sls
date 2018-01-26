{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

query_api:
  http.query:
    - name: http://localhost:8000/run
    - method: POST
    - header_list: '["Accept: application/json"]'
    - verify_ssl: False
    - data: 'username={{ params.api_user }}&password={{ params.api_passwd }}&eauth=pam&client=local&tgt=*&fun=test.ping'
    - status: 200
