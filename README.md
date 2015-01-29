salt-pkg-install-tests
======================

Salt states to automate salt package installation testing.

- add the VM to the roster:
```
cat >> /etc/salt/roster
<minion-name>
  host: <minion-hostname-or-IP>
```
- `salt-ssh -i <minion-name> state.sls test_install` and you're off to the races
- currently only works for [debian testing](http://debian.saltstack.com/), [ubuntu PPA](https://launchpad.net/~saltstack/), and [RedHat COPR](http://copr.fedoraproject.org/coprs/saltstack/salt/) packages
