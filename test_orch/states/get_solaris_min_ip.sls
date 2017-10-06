#!py

def run():
    config = {}
    target_host = __pillar__['host']
    query_ip  = __salt__['cmd.run']('salt-ssh solaris cmd.run "zlogin {0} ipadm show-addr net0/v4"'.format(target_host))
    host_ip = ''.join(query_ip.split()[-1:]).replace("/16", "")

    config['add_solaris_minion_roster'] = {
        'file': [
            'append',
            {'name': '/etc/salt/roster'},
            {'template': 'jinja'},
            {'source': 'salt://test_orch/files/solaris_minion_ip'},
            {'context': {'solarismin_ip': host_ip}},
        ],
    }


    return config
