#!py

def run():
    config = {}
    test = True
    while test == True:
        query_dns = __salt__['cmd.retcode']('ping -c 1 {0}'.format(__pillar__['hostname']))
        if query_dns == 0:
            test == False
            break
    return config
