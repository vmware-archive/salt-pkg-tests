include:
  - salt-pkg-install-tests.install_salt

# Update mirrors
yum_update:
  cmd.run:
    - name: yum makecache -y
    - require_in:
      - cmd: salt-master
      - cmd: salt-minion
      - cmd: salt-api
      - cmd: salt-cloud
      - cmd: salt-ssh
      - cmd: salt-syndic
