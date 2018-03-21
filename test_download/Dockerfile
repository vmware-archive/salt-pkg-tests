FROM centos:7

RUN yum -y install yum-utils
RUN yum -y groupinstall development
RUN yum -y install https://centos7.iuscommunity.org/ius-release.rpm
RUN yum -y install python36u python36u-pip python36u-devel git
RUN pip3.6 install bs4 requests
RUN mkdir /testing/
RUN git clone https://github.com/saltstack/salt-pkg-tests.git /testing/
