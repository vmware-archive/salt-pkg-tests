==========================
Test PKGS using salt-cloud
==========================

This orchestration file allows you to test saltstack packages with VMs
in the cloud. You will need to do the following in order to test pkgs
using this orchestration sls file.

1. Add test_orch directory to file_roots
2. Add pillar data. This orchestration file is dependent on some pillar
   values. The following is an example of some pillar data:

       salt_version: 2016.3.2
       upgrade_salt_version: 2016.3.1
       dev: staging
       orch_master: pkg-test-minion
       username: ch3ll
       upgrade: True
       clean: True
       latest: False
       repo: community
       rc_pkgs_url: 'salt_rc'
       cloud_profile:
         - linode_ubuntu12
         - linode_ubuntu14

   Explanation of options:
     salt_version
         The version of salt you want to test.

     upgrade_salt_version
         If testing an upgrade this is the version you
         will initially install before upgrading to the
         version in salt_version

     dev
         This specifies whether you are testing staging,testing,dev or
         another directory where the packages are located.

     rc_pkgs_url
         Specifies the name of the RC packages url if testing rc packages.
         For example: salt_rc. Leave either blank: '' or do not set if not
         testing rc packages.

     orch_master
         the name of the minion on your master

     username
         this is simply an identifying mechanism. To be able to identify
         which VMs in the cloud you are building and destroying

     upgrade
         True if you want to test an upgrade, False if you do not want to.

     clean
         True if you want to test a clean install of the salt packages.

     latest
         True if you want to test the latest URLs. False if you want to
         test the archive links.

     repo
         Specifies if you are testing community or saltstack packages.
         Select community or saltstack, depending on what you are testing.
         
     cloud_profile:
         A list of the salt-cloud profiles that you want to test.
         As the example shows we will test Ubuntu 12 and 14, which
         we have specified in /etc/salt/cloud.profiles.d/linode.conf

3. Now you are ready to run the orchestration file. In order to do this you simply
   need to run: 'salt-run state.orchestrate test_orch.pkg-test'. This will run the
   tests and you will see the results in the end of the run.


====================
Testing Windows PKGs
====================

1. Need to add the following to /etc/salt/master:
   reactor:
     - 'salt/cloud/qapkgtest-master-linux/deploying':
           - /srv/reactor/win_reactor.sls

   TODO: add this as part of the orchestration

2. Need to edit the file: test_orch/states/windowsmap and change the name of the profiles that are implemented in your current architecture
   TODO: add ability to dynamically add profiles from pillars for all windows profiles
