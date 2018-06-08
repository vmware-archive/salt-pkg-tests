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
        help='Specify if you want to use staging url or not'
    )
    parser.add_argument(
        '-b', '--branch',
        help='Specify the salt branch'
    )
    parser.add_argument(
        '--prev-branch',
        help='Specify the previous salt branch'
    )
    parser.add_argument(
        '-u', '--user',
        help='Specify the user to auth with repo'
    )
    parser.add_argument(
        '-p', '--passwd',
        help='Specify the password to auth with repo'
    )

    return parser

def print_flush(*args, **kwargs):
    print(*args, **kwargs)
    sys.stdout.flush()

def get_url(args):
    if 'ubuntu' in args.os:
        os_v = args.os[-2:] + '.04'
    else:
        os_v = args.os[-1:]

    repo_url = 'https://repo.saltstack.com/'
    if args.user:
        repo_url = 'https://{0}:{1}@repo.saltstack.com/'.format(args.user, args.passwd)

    amazon_url = 'yum/amazon/'
    redhat_url = 'yum/redhat/'
    debian_url = 'apt/debian/'
    ubuntu_url = 'apt/ubuntu/'
    windows_url = 'windows/'
    redhat_arch = '/x86_64/'
    debian_arch = '/amd64/'
    pi_arch = '/armhf/'

    if args.branch:
        version = args.branch
    else:
        version = 'latest'

    if args.staging:
        repo_url=repo_url + 'staging/'

    if 'centos' in args.os:
        url = repo_url + redhat_url + os_v + redhat_arch + version
    elif 'debian' in args.os:
        url = repo_url + debian_url + os_v + debian_arch + version
    elif 'ubuntu' in args.os:
        url = repo_url + ubuntu_url + os_v + debian_arch + version
    elif 'pi' in args.os:
        url = repo_url + debian_url + '8' + pi_arch + version
    elif 'osx' in args.os:
        url = repo_url + 'osx'
    elif 'amazon' in args.os:
        if args.branch == '2016.3':
            url = repo_url + redhat_url + '6' + redhat_arch + version
        else:
            url = repo_url + amazon_url + 'latest' + redhat_arch + version
    elif 'windows' in args.os:
        url = repo_url + windows_url
    return url

def get_salt_version(url, args, prev_branch=False):
    if 'osx' not in url and prev_branch:
        url = url.replace(url.split('/')[-1], args)
    get_url = requests.get(url)
    ret_code = get_url.status_code
    if ret_code != 200:
        print('Attempt to query url failed with http error code: {0}'.format(ret_code))
        sys.exit(1)
    html = get_url.content
    parse_html = bsoup(html)
    pkg_name = 'salt-master'
    if 'osx' in url:
        try:
            pkg_name = 'salt-{0}'.format(args.branch)
        except AttributeError:
            pkg_name = 'salt-{0}'.format(args)
    if 'windows' in url:
        pkg_name = 'Salt-Minion-{0}'.format(args.branch)

    for tag in parse_html.findAll(attrs={'href': re.compile(pkg_name +
                                                           ".*")}):
        match = re.search("([0-9]{1,4}\.)([0-9]{1,2}\.)([0-9]{1,2})", str(tag))
        salt_ver = (match.group(0))
    return salt_ver

def set_env_vars(**kwargs):
    salt_version = kwargs.get('salt_version')
    ver_split = salt_version.split(".")
    year = ver_split[0]
    month = ver_split[1]
    release = ver_split[2]
    upgrade_from_version = year + '.' + month + '.' + str((int(release) -1))
    if kwargs['salt_version'].split('.')[-1:][0] == '0':
        upgrade_from_version = get_salt_version(kwargs['url'], kwargs['prev_branch'], prev_branch=True)
    branch = year + '.' + month

    output = []
    output.append('SALT_VERSION={0}'.format(salt_version))
    output.append('UPGRADE_VERSION={0}'.format(upgrade_from_version))
    output.append('SALT_BRANCH={0}'.format(branch))

    print_flush('\n\n{0}\n\n'.format('\n'.join(output)))


def main():
    parser = get_args()
    args = parser.parse_args()
    url = get_url(args)
    current_salt_ver = get_salt_version(url, args)
    get_opts = set_env_vars(url=url, salt_version=current_salt_ver, prev_branch=args.prev_branch)

if __name__ == '__main__':
    main()
