#!py

def run():
    config = {}
    target_host = __pillar__['linux_master']
    get_host  = __salt__['cloud.get_instance'](target_host)
    if get_host.get('private_ips'):
        ip = get_host['private_ips']

    config['add_linux_master_roster'] = {
        'file': [
            'append',
            {'name': '/etc/salt/roster'},
            {'template': 'jinja'},
            {'source': 'salt://test_orch/files/win_master_ip'},
            {'context': {'host_ip': ip,
                         'linux_master': __pillar__['linux_master'],
                         'linux_master_user': __pillar__['linux_master_user'],
                         'linux_master_key': __pillar__['linux_master_key']}},
        ],
    }

    return config
