#!/usr/bin/env python

#import python modules
import optparse
import sys

#import salt modules
import salt.client
import salt.config
import salt.runner
from salt.exceptions import CommandExecutionError 

__opts__ = salt.config.minion_config('/etc/salt/minion')
__opts__['file_client'] = 'local'
caller = salt.client.Caller(mopts=__opts__)

def get_args():
    parser = optparse.OptionParser()
    parser.add_option("-m", "--minion", dest="minion",
                      help="Specify minion target")
    parser.add_option("-a", "--all", action="store_true", dest="all",
                      help="Only check version of all salt cli cmds")
    parser.add_option("-v", "--version", dest="version",
                      help="Check this version of salt is installed")
    return parser

def check_all_cmds(args):
    salt_cli_cmds = ['salt', 'salt-call', 'salt-minion',
                     'salt-master', 'salt-cloud', 'salt-ssh',
                     'salt-syndic', 'salt-cloud', 'salt-api']
    salt_version = args.version
    failed_cmds = []
    failed_vers = []

    for cmd in salt_cli_cmds:
        try:
            check_version = caller.cmd('cmd.run', '{0} --version'.format(cmd))
            if salt_version in check_version:
                pass
            else:
                failed_vers.append(cmd)
        except CommandExecutionError:
            failed_cmds.append(cmd)

    if failed_cmds or failed_vers: 
        for cmd in failed_cmds:
            print('{0} does not exist or was not installed properly'.format(cmd))
        for cmd in failed_vers:
            print('{0}\'s version does not match version: {1}'.format(cmd, salt_version))
        sys.exit(1)

def check_cmd_returns(args):
    local = salt.client.LocalClient()
    salt_minion = args.minion
    salt_version = args.version

    cmd_check1 = local.cmd(salt_minion, 'test.version')[salt_minion]
    cmd_check2 = caller.cmd('test.version')
    cmd_check3 = local.cmd(salt_minion, 'cmd.run', ['salt --version'])
    version_cmd_checks = [cmd_check1, cmd_check2, cmd_check3]

    for cmd in version_cmd_checks:
        if cmd == salt_version:
            sys.exit(0)
        else:
            print('{0}\' does not match version: {1}'.format(cmd, salt_version))
            sys.exit(1)

def main():
    parser = get_args()
    (args, options) = parser.parse_args()
    if args.all:
        check_all_cmds(args)
    else:
        check_all_cmds(args)
        check_cmd_returns(args)


if __name__ == '__main__':
    main()
