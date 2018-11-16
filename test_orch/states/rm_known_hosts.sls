#!py

def run():
    import salt.loader
    from salt.ext import six
    from salt.roster import get_roster_file
    from salt.template import compile_template

    config = {}
    host = __pillar__['host']
    template = get_roster_file(__opts__)

    rend = salt.loader.render(__opts__, {})
    raw = compile_template(template,
                           rend,
                           __opts__['renderer'],
                           __opts__['renderer_blacklist'],
                           __opts__['renderer_whitelist'],
                           )

    conditioned_raw = {}
    for minion in raw:
        conditioned_raw[six.text_type(minion)] = salt.config.apply_sdb(raw[minion])

    config['clean_up_known_hosts'] = {
        'ssh_known_hosts': [
            'absent',
            {'name': conditioned_raw[host]['host']},
            {'user': 'root'}
        ],
    }

    return config
