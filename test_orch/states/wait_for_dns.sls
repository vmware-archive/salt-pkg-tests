#!py
import time

def run():
    config = {}
    target_host = __pillar__['hostname']
    test = True
    future = time.time() + 600
    while test == True:
        if time.time() > future:
            raise Exception('cannot get DNS for vm: {0}'.format(target_host))
        query_dns = __salt__['cmd.retcode']('salt-ssh {0} test.ping -i'.format(target_host))
        if query_dns == 0:
            test == False
            break

    config['vm-created'] = {
        'cmd': [
            'run',
            {'name': 'echo {0} VM has been created'.format(target_host)},
        ],
    }

    return config
