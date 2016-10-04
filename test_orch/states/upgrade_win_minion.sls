install_pygit2:
  pkg.installed:
    - name: python-pygit2
    - reload_modules: true
add_custom_salt_pkg_file:
  file.managed:
    - name: /srv/salt/win/repo-ng/cust_salt_minion.sls
    - makedirs: True
    - source: salt://test_orch/states/cust_salt_minion
    - template: jinja
generate_repo:
  cmd.run:
    - name: salt-run winrepo.genrepo
refresh_win_db:
  cmd.run:
    - name: salt -G 'os:windows' pkg.refresh_db
upgrade_minion:
  cmd.run:
    - name: salt -G 'os:windows' pkg.install cust_salt_minion -t 30
