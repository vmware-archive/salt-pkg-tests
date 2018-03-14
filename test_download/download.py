#!/usr/bin/python
from BeautifulSoup import BeautifulSoup as bsoup
import BeautifulSoup
from shutil import copyfile
import argparse
import requests
import re
import os
import tempfile

# Miscellaneous variables
TMP_DIR = tempfile.mkdtemp()
LATEST = '2017.7'

check_steps = []
os_tabs = ['tab1-raspbian', 'tab2-raspbian', 'tab3-raspbian',
           'tab1-amzn', 'tab2-amzn', 'tab3-amzn',
           'tab1-debian', 'tab2-debian', 'tab3-debian',
           'tab1-redhat', 'tab2-redhat', 'tab3-redhat',
           'tab1-ubuntu', 'tab2-ubuntu', 'tab3-ubuntu']

def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-b', '--branch',
        help='Specific salt branch. Ex. 2016.3'
    )
    parser.add_argument(
        '-s', '--staging',
        action='store_true',
        help='Specific salt branch. Ex. 2016.3'
    )
    parser.add_argument(
        '-v', '--salt-version',
        help='Specific salt version. Ex. 2017.7.3'
    )
    parser.add_argument('-u', '--user',
        help='Specify the user to auth with repo')
    parser.add_argument('-p', '--passwd',
        help='Specify the password to auth with repo')

    return parser

def det_os_family(os):
    return {'tab1-raspbian': 'raspbian',
            'tab2-raspbian': 'raspbian',
            'tab3-raspbian': 'raspbian',
            'tab1-amzn': 'amzn',
            'tab2-amzn': 'amzn',
            'tab3-amzn': 'amzn',
            'tab1-debian': 'debian',
            'tab2-debian': 'debian',
            'tab3-debian': 'debian',
            'tab1-redhat': 'redhat',
            'tab2-redhat': 'redhat',
            'tab3-redhat': 'redhat',
            'tab1-ubuntu': 'ubuntu',
            'tab2-ubuntu': 'ubuntu',
            'tab3-ubuntu': 'ubuntu',
           }[os]

def det_os_versions(os_v):
    return {'raspbian': ['raspbian'],
            'amzn': ['amzn'],
            'debian': ['debian8', 'debian9'],
            'redhat': ['redhat6', 'redhat7'],
            'ubuntu': ['ubuntu14', 'ubuntu16'],
           }[os_v]

def determine_release(current_os):
    '''
    Helper method to determine release type
    '''
    if 'tab1' in current_os:
        release='latest'
    elif 'tab2' in current_os:
        release='major'
    elif 'tab3' in current_os:
        release='minor'
    return release

def _get_url(url):
    print('Querying url: {0}'.format(url))
    get_url = requests.get(url)
    if get_url.status_code != 200:
        raise Exception('url {0} did not return 200'.format(url))
    return get_url

def _get_dependencies(url):
    version = args.salt_version.replace('.', '_')
    os = url.split('/')[4]
    os_version = url.split('/')[5].split('.')[0]
    print('Determining dependencies for {0}'.format(os))
    dep_sls = _get_url('https://raw.githubusercontent.com/saltstack/salt-pack/develop/file_roots/versions/{0}/{1}_pkg.sls'.format(version, os)).text
    if 'redhat' in url:
        os = 'rhel'
    deps = [x.split('.')[1].split('-')[-1:][0] for x in re.findall('pkg.*.{0}{1}'.format(os, os_version), dep_sls)]
    if 'amazon' in url:
        deps = [x.split('.')[1].split('-')[-1:][0] for x in re.findall('pkg.*.amzn', dep_sls)]

    #remove comments
    comments = re.findall('\#\#    \- pkg.*.*.{0}{1}'.format(os, os_version), dep_sls)
    if comments:
        for comment in comments:
            deps.remove(comment.split('.')[1].split('-')[-1:][0])

    remove_deps = ['importlib', 'pyzmq', 'ssl_match_hostname']
    if 'armhf' in url:
        remove_deps = ['libnacl', 'cherrypy', 'croniter', 'crypto', 'enum34',
                       'jinja2', 'libnacl', 'msgpack', 'requests', 'urllib3',
                       'yaml']
    for removal in remove_deps:
        # some of these deps are not in the repo, remove them from check
        if removal in str(deps):
            deps.remove(removal)
    return deps

def download_check(urls, salt_version, os, branch=None):
    '''
    helper method that will clean up the steps for automation
    '''
    for url in urls:
        if 'KEY' in url:
            _get_url(url)
        else:
            pkgs = []
            if 'apt' in url:
                pkg_format = '_'
                pkgs.append('salt-common{0}{1}'.format(pkg_format, salt_version))
            if any(x in url for x in ['redhat', 'amazon']):
                if 'rpm' in url:
                    _get_url(url)
                if any(x in url for x in ['$releasever', '$basearch']):
                    url = url.replace('$releasever', os_v[-1:]).replace('$basearch', 'x86_64') + salt_version
                if 'archive' not in url and 'redhat' in url:
                    url = '/'.join(url.split('/')[:-1]) + '/' + os_v[-1:] + '/x86_64/' + branch
                elif 'archive' not in url and 'amazon' in url:
                    url = '/'.join(url.split('/')[:-1]) + '/latest/x86_64/' + branch
                pkg_format = '-'
                pkgs.append('salt-{1}'.format(pkg_format, salt_version))

            pkgs.extend(_get_dependencies(url))
            pkgs.extend(['salt-api{0}{1}'.format(pkg_format, salt_version),
                         'salt-cloud{0}{1}'.format(pkg_format, salt_version),
                         'salt-minion{0}{1}'.format(pkg_format, salt_version),
                         'salt-master{0}{1}'.format(pkg_format, salt_version),
                         'salt-ssh{0}{1}'.format(pkg_format, salt_version),
                         'salt-syndic{0}{1}'.format(pkg_format, salt_version)])

            print('Querying url: {0}'.format(url))
            contents = _get_url(url).text
            for pkg in pkgs:
                if isinstance(pkg, list):
                    pkg = str(pkg[0])
                print('Checking for pkg: {0}'.format(pkg))
                if pkg not in contents.lower():
                    raise Exception('The dependency {0} from the url {1} is not \
                          available.'.format(pkg, url))

def parse_html_method(tab_os, os_v, args):
    '''
    Parse the index.html for install commands
    '''
    urls = []
    def _add_urls(cmd):
        if 'http' in str(cmd):
            link = re.findall('http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+',
                       str(cmd))[0]
            if link not in urls:
                if args.branch != LATEST and 'latest' in link:
                    print('Not testing link: {0} because latest is not available on branch: {1}'.format(link, args.branch))
                else:
                    urls.append(link.split('<')[0])

    # Get and Parse index page
    if args.staging:
        url = 'https://{0}:{1}@repo.saltstack.com/staging/{2}.html'.format(args.user, args.passwd,
                                                                          'index' if args.branch == LATEST else args.branch)
    else:
        url = 'https://repo.saltstack.com/{0}.html'.format('index' if args.branch == LATEST else args.branch)


    get_url = requests.get(url)
    if get_url.status_code != 200:
        raise Exception('url {0} did not return 200'.format(get_url))
    html = get_url.content
    parse_html = bsoup(html)

    # for loop over all tags and find http urls
    for tag in parse_html.findAll(attrs={'id' : tab_os}):
        for tab_os_v in tag.findAll(attrs={'class': re.compile(os_v + ".*")}):
            for cmd in tab_os_v.findAll(attrs={'class': 'language-bash'}):
                _add_urls(cmd)
            for cmd_2 in tab_os_v.findAll(attrs={'class': 'language-ini'}):
                _add_urls(cmd_2)
        # get all instructions that run on both veresion of each os_family
        for cmd_all in tag.findAll('code', attrs={'class': None}):
            _add_urls(cmd_all)

    return urls

for current_os in os_tabs:
    parser = get_args()
    args = parser.parse_args()
    os_family = det_os_family(current_os)
    release = determine_release(current_os)
    os_versions = det_os_versions(os_family)
    for os_v in os_versions:
        print('++++++++++++++++++++++++++++++++++')
        print('Testing OS: {0} Release: {1}'.format(os_v, release))
        print('++++++++++++++++++++++++++++++++++')
        os_instr = parse_html_method(current_os, os_v, args)
        download_check(os_instr, args.salt_version, os_v,
                               branch=release if release == 'latest' else args.branch)
