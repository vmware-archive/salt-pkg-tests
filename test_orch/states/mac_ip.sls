#!py
import re
import time

def run():
    config = {}
    mac_min = __pillar__['host']
    query_ip  = __salt__['cmd.run']('salt-ssh "mac*" cmd.run "/opt/salt/bin/salt-call --local parallels.exec {0} ifconfig runas=parallels"'.format(mac_min))
    for value in query_ip.split():
      ip_p = re.compile('^10.[0-9]')
      if ip_p.match(value) and '255' not in value:
        ip_addr = str(value)

    config['add_mac_minion_roster'] = {
        'file': [
            'append',
            {'name': '/etc/salt/roster'},
            {'template': 'jinja'},
            {'source': 'salt://test_orch/files/mac_minion_ip'},
            {'context': {'mac_ip': ip_addr}},
        ],
    }


    return config
