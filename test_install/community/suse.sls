{% set os_ = salt['grains.get']('os', '') %}
{% set osrelease = salt['grains.get']('osrelease', '') %}
{% set codename = salt['pillar.get']('codename', '') %}
{% set pkgs = ['salt-master', 'salt-minion', 'salt-api', 'salt-cloud', 'salt-ssh', 'salt-syndic'] %}
{% set salt_version = salt['pillar.get']('salt_version', '') %}

# test for codenames
{% if codename == '' %}
  {% set release = osrelease %}
{% else %}
  {% set release = codename %}
{% endif %}

{% if salt_version %}
  {% set versioned_pkgs = [] %}
  {% for pkg in pkgs %}
    {% do versioned_pkgs.append(pkg + '-' + salt_version) %}
  {% endfor %}
  {% set pkgs = versioned_pkgs %}
{% endif %}

get-key:
  cmd.run:
    - name: zypper --gpg-auto-import-keys refresh

add-repository:
  file.managed:
    - name: /etc/zypp/repos.d/devel_languages_python.repo
    - makedirs: True
    - contents: |
        [devel_languages_python]
        name=Python Modules (openSUSE_13.2)
        enabled=1
        autorefresh=0
        baseurl=http://download.opensuse.org/repositories/devel:/languages:/python/{{ os_ }}_{{ release }}/
        type=rpm-md
        gpgcheck=1
        gpgkey=http://download.opensuse.org/repositories/devel:/languages:/python/{{ os_ }}_{{ release }}/repodata/repomd.xml.key

refresh:
  module.run:
    - name: pkg.refresh_db
    - require:
      - file: add-repository
      - cmd: get-key

# Install salt packages
install-salt:
  pkg.installed:
    - name: salt-pkgs
    - pkgs: {{ pkgs }}
    - require:
      - module: refresh
