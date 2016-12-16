#!/usr/bin/python

from __future__ import print_function
from BeautifulSoup import BeautifulSoup as bsoup
import BeautifulSoup
import re
import requests
import argparse
import os
import sys

def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-o', '--os',
        help='Specific OS. Ex. centos7'
    )
    parser.add_argument(
        '-s', '--staging',
        action='store_true',
        help='Specify if you want to use stagign url or not'
    )
    return parser

def print_flush(*args, **kwargs):
    print(*args, **kwargs)
    sys.stdout.flush()

def get_url(args):
    os_v = args.os[-1:]
    repo_url = 'https://repo.saltstack.com/'

    redhat_url = 'yum/redhat/'
    debian_url = 'apt/debian/'
    ubuntu_url = 'apt/ubuntu/'
    redhat_arch = '/x86_64/'
    debian_arch = '/amd64/'
    version = 'latest'

    if args.staging:
        repo_url=repo_url + 'staging/'

    if 'centos' in args.os:
        url = repo_url + redhat_url + os_v + redhat_arch + version
    elif 'debian' in args.os:
        url = repo_url + debian_url + os_v + debian_arch + version
    elif 'ubuntu' in args.os:
        url = repo_url + ubuntu_url + os_v + debian_arch + version
    return url

def set_env_vars(**kwargs):
    salt_version = kwargs.get('salt_version')
    ver_split = salt_version.split(".")
    year = ver_split[0]
    month = ver_split[1]
    release = ver_split[2]
    upgrade_from_version = year + '.' + month + '.' + str((int(release) -1))

    output = []
    output.append('SALT_VERSION={0}'.format(salt_version))
    output.append('UPGRADE_VERSION={0}'.format(upgrade_from_version))

    print_flush('\n\n{0}\n\n'.format('\n'.join(output)))

def get_salt_version(url):
    get_url = requests.get(url)
    html = get_url.content
    parse_html = bsoup(html)

    for tag in parse_html.findAll(attrs={'href': re.compile('salt-master' +
                                                           ".*")}):
        match = re.search("([0-9]{1,4}\.)([0-9]{1,2}\.)([0-9]{1,2})", str(tag))
        salt_ver = (match.group(0))
    return salt_ver

def main():
    parser = get_args()
    args = parser.parse_args()
    url = get_url(args)
    current_salt_ver = get_salt_version(url)
    get_opts = set_env_vars(salt_version=current_salt_ver)

if __name__ == '__main__':
    main()
