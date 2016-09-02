{% set branch = salt_version.rsplit('.', 1)[0] %}

from {{ distro }}:{{ tag }}
{% if 'debian' in osflavor %}

RUN apt-get update
RUN apt-get -y install wget
RUN if ! dpkg -l ca-certificates > /dev/null; then apt-get install ca-certificates -y; else exit 0; fi

  {% if 'latest' in install_type %}
  RUN wget -O - https://repo.saltstack.com{{ staging }}apt/{{ distro }}/{{ os_version }}/amd64/latest/SALTSTACK-GPG-KEY.pub | apt-key add -
  RUN echo deb http://repo.saltstack.com{{ staging }}apt/{{ distro }}/{{ os_version }}/amd64/latest {{ codename }} main >> /etc/apt/sources.list

  {% elif 'major' in install_type %}
  RUN wget -O - https://repo.saltstack.com{{ staging }}apt/{{ distro }}/{{ os_version }}/amd64/{{ branch }}/SALTSTACK-GPG-KEY.pub | apt-key add -
  RUN echo deb http://repo.saltstack.com{{ staging }}apt/{{ distro }}/{{ os_version }}/amd64/{{ branch }} {{ codename }} main >> /etc/apt/sources.list

  {% elif 'minor' in install_type %}
  RUN wget -O - https://repo.saltstack.com{{ staging }}apt/{{ distro }}/{{ os_version }}/amd64/archive/{{ salt_version }}/SALTSTACK-GPG-KEY.pub | apt-key add -
  RUN echo deb http://repo.saltstack.com{{ staging }}apt/{{ distro }}/{{ os_version }}/amd64/archive/{{ salt_version }} {{ codename }} main >> /etc/apt/sources.list
  {% endif %}
RUN apt-get update -y
RUN apt-get -y install salt-minion salt-master salt-ssh salt-syndic salt-cloud salt-api

{% elif 'centos' in os %}
  RUN if ! type wget > /dev/null; then yum install wget -y; fi

  {% if 'latest' in install_type %}
  RUN {{ install_cmd }} https://repo.saltstack.com{{ staging }}yum/redhat/salt-repo-latest-{{ repo_pkg_vr }}.el{{ os_version }}.noarch.rpm 
    {% if on_cent5 %}
      RUN rpm -ivh salt-repo-latest-{{ repo_pkg_vr }}.el5.noarch.rpm
    {% endif %}

  {% elif 'major' in install_type %}
    RUN {{ install_cmd }} https://repo.saltstack.com{{ staging }}yum/redhat/salt-repo-{{ branch }}-{{ repo_pkg_vr }}.el{{ os_version }}.noarch.rpm 
    {% if on_cent5 %}
      RUN rpm -ivh salt-repo-{{ branch }}-{{ repo_pkg_vr }}.el5.noarch.rpm
    {% endif %}
 
  {% elif 'minor' in install_type %}
    {% if on_cent5 %}
      RUN {{ install_cmd }} https://repo.saltstack.com{{ staging }}yum/redhat/5/x86_64/archive/{{ salt_version }}/SALTSTACK-EL5-GPG-KEY.pub
      RUN rpm --import SALTSTACK-EL5-GPG-KEY.pub 
    {% else %}
      RUN rpm --import https://repo.saltstack.com{{ staging }}yum/redhat/{{ os_version }}/x86_64/archive/{{ salt_version }}/SALTSTACK-GPG-KEY.pub
    {% endif %}

  RUN printf "[saltstack-repo]\n\
name=SaltStack repo for RHEL/CentOS \$releasever\n\
baseurl=https://repo.saltstack.com/yum/redhat/\$releasever/\$basearch/archive/{{ salt_version }}\n\
enabled=1\n\
gpgcheck=1\n\
gpgkey=https://repo.saltstack.com/yum/redhat/\$releasever/\$basearch/archive/{{ salt_version }}/SALTSTACK-GPG-KEY.pub" >> /etc/yum.repos.d/saltstack.repo
  {% endif %}
  {% if staging == '/staging/' %}
  RUN sed -i 's/com\/yum/com\/staging\/yum/' /etc/yum.repos.d/salt*.repo
  {% endif %}
RUN yum install -y salt-minion salt-master salt-ssh salt-syndic salt-cloud salt-api

{% endif %}
