from {{ distro }}:{{ tag }}
COPY install_salt.sh /tmp/install_salt.sh
RUN bash /tmp/install_salt.sh

{% if 'debian' in osflavor %}

RUN apt-get update
RUN apt-get -y install wget sudo
RUN if ! dpkg -l ca-certificates > /dev/null; then apt-get install ca-certificates -y; else exit 0; fi

{% elif 'centos' in os %}
  RUN if ! type wget > /dev/null; then yum install wget -y; fi

  {% if staging == '/staging/' %}
  RUN sed -i 's/com\/yum/com\/staging\/yum/' /etc/yum.repos.d/salt*.repo
  {% endif %}

{% endif %}
