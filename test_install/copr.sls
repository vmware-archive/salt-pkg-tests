{% set os_family = salt['grains.get']('os_family', '') %}
{% set os_ = salt['grains.get']('os', '') %}
{% set os_major_release = salt['grains.get']('osmajorrelease', '') %}
{% set pkgs = ['salt-master', 'salt-minion', 'salt-api', 'salt-cloud', 'salt-ssh', 'salt-syndic'] %}

{% set on_redhat = os_family == 'RedHat' %}
{% set on_redhat_5 = os_major_release == '5' %}
{% set on_fedora = os_ == 'Fedora' %}


{% if on_redhat %}
# CentOS/RHEL 5 has its own, separate COPR Repo
{% if on_redhat_5 %}
copr:
  pkgrepo.managed:
    - humanname: Copr repo for salt owned by saltstack
    - baseurl: https://copr-be.cloud.fedoraproject.org/results/saltstack/salt-el5/epel-5-$basearch/
    - gpgkey: https://copr-be.cloud.fedoraproject.org/results/saltstack/salt-el5/pubkey.gpg
    - gpgcheck: 1
    - skip_if_unavailable: True
    - enabled: 1
{% else %}
    # Set the repo_type for Fedora vs. EPEL for the COPR Repo
    {% set repo_type = 'fedora' if on_fedora else 'epel' %}
copr:
  pkgrepo.managed:
    - humanname: Copr repo for Salt owned by SaltStack
    - baseurl: http://copr-be.cloud.fedoraproject.org/results/saltstack/salt/{{ repo_type }}-{{ os_major_release }}-$basearch/
    - gpgcheck: 0
    - skip_if_unavailable: True
    - enabled: 1
{% endif %}

# COPR relies on some EPEL packages, so let's install EPEL now
{% if not on_fedora %}
epel:
  pkg.installed:
    - name: epel-release
{% endif %}

refresh:
  module.run:
    - name: pkg.refresh_db
    - requires:
      - pkgrepo: copr
      {% if not on_fedora %}
      - pkg: epel
      {% endif %}

refresh_backup:
  cmd.run:
    - name: yum -y makecache
    - onfail:
      - module: refresh

# Install salt packages
install-pkgs:
  pkg.installed:
    - names: {{ pkgs }}
    - requires:
      - module: refresh
{% endif %}
