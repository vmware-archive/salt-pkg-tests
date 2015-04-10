{% set os = salt['grains.get']('os', '') %}
{% set os_major_release = salt['grains.get']('osmajorrelease', '') %}
{% set pkgs = ['salt-master', 'salt-minion', 'salt-api', 'salt-cloud', 'salt-ssh', 'salt-syndic'] %}

# CentOS/RHEL 5 has its own, separate COPR Repo
{% if os_major_release == '5' %}
copr:
  pkgrepo.managed:
    - humanname: Copr repo for salt owned by saltstack
    - baseurl: https://copr-be.cloud.fedoraproject.org/results/saltstack/salt-el5/epel-5-$basearch/
    - gpgkey: https://copr-be.cloud.fedoraproject.org/results/saltstack/salt-el5/pubkey.gpg
    - gpgcheck: 1
    - skip_if_unavailable: True
    - enabled: 1

{% else %}

    # Set the repotype for Fedora vs. EPEL for the COPR Repo
    {% if salt['grains.get']('os', '') == 'Fedora' %}
        {% set repotype = 'fedora' %}
    {% else %}
        {% set repotype = 'epel' %}
    {% endif %}

copr:
  pkgrepo.managed:
    - humanname: Copr repo for Salt owned by SaltStack
    - baseurl: http://copr-be.cloud.fedoraproject.org/results/saltstack/salt/{{ repotype }}-{{ os_major_release }}-$basearch/
    - gpgcheck: 0
    - skip_if_unavailable: True
    - enabled: 1

{% endif %}

# COPR relies on some EPEL packages, so let's install EPEL now
{% if os != 'Fedora' %}
# Install Epel
epel:
  cmd.run:
    - name: yum -y install epel-release
{% endif %}

# Install salt packages
{% for pkg in pkgs %}
{{ pkg }}:
  cmd.run:
    - name: yum -y install {{ pkg }}
{% endfor %}
