{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

{% set esky_pkg = 'http://pkg.blackdot.be/extras/salt-{0}-esky-smartos.tar.gz'.format(params.salt_version) %}

esky_pkg:
  archive.extracted:
    - name: /opt/
    - source: {{ esky_pkg }}
    - tar_options: xvpz
    - archive_format: tar
    - skip_verify: True
    - if_missing: /opt/salt/

run_installer:
  cmd.run:
    - name: sh /opt/salt/install/install.sh
    - require:
      - archive: esky_pkg
