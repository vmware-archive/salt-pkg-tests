#!py

def run():
    config = {}
    target_host = __pillar__['linux_master']
    get_host  = __salt__['cloud.get_instance'](target_host)
    if get_host.get('public_ips'):
        ip = get_host['public_ips'][0]

    config['add_linux_master_roster'] = {
        'file': [
            'append',
            {'name': '/etc/salt/roster'},
            {'template': 'jinja'},
            {'source': 'salt://test_orch/files/win_master_ip'},
            {'context': {'host_ip': ip,
                         'linux_master': __pillar__['linux_master'],
                         'linux_master_user': __pillar__['linux_master_user'],
                         'linux_master_passwd': __pillar__['linux_master_passwd']}},
        ],
    }

    return config
