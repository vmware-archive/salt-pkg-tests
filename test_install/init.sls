{% set os = salt['grains.get']('os', '') %}
{% set os_family = salt['grains.get']('os_family', '') %}
{% set os_major_release = salt['grains.get']('osmajorrelease', '') %}

{% if os_family == 'RedHat' %}
  {% if os == 'Fedora' %}
    {% set repotype = 'fedora' %}
  {% else %}
    {% set repotype = 'epel' %}
  {% endif %}

include:
   - test_install.epel

{% if os_major_release == '5' %}
python-hashlib:
  pkg.installed:
    - require_in:
      - pkgrepo: saltstack-copr
{% endif %}

saltstack-copr:
  pkgrepo.managed:
    - humanname: Copr repo for salt owned by saltstack
    - baseurl: http://copr-be.cloud.fedoraproject.org/results/saltstack/salt/{{ repotype }}-$releasever-$basearch/
    - gpgcheck: 0
    - skip_if_unavailable: True
    - enabled: 1
    - require_in:
      - cmd: yum_update

{% elif os == 'Debian' %}
include:
  - test_install.debian

# Get the GPG key for Debian/Ubuntu Packages
debian_key:
  cmd.run:
    - name: wget -O - http://debian.saltstack.com/debian-salt-team-joehealy.gpg.key|apt-key add -
    - require_in:
      - file: sources_list_prep

{% endif %}
