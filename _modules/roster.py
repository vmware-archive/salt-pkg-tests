# import python libraries
import logging

# import salt libraries
import salt.utils.files
import salt.utils.yaml

log = logging.getLogger(__name__)

def remove(roster, name):
    '''
    remove an entry from the salt-ssh roster
    '''
    with salt.utils.files.fopen(roster, 'r') as conf:
        roster_txt = conf.read()
        roster_yaml = salt.utils.yaml.safe_load(roster_txt)
    try:
        del roster_yaml[name]
    except KeyError:
        log.error('{0} does not exist in roster file {1}'.format(name, roster))
        return False

    try:
        with salt.utils.files.fopen(roster, 'w+') as conf:
            salt.utils.yaml.safe_dump(roster_yaml, conf, default_flow_style=False)
    except (IOError, OSError):
        log.error('Unable to delete {0} from roster file {1}'.format(name, roster))
        return False

