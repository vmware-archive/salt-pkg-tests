#!/usr/bin/python
from bs4 import BeautifulSoup as bsoup
from shutil import copyfile
import argparse
import hashlib
import requests
import re
import os
import subprocess
import tempfile

# Miscellaneous variables
TMP_DIR = tempfile.mkdtemp()
LATEST = '2018.3'

check_steps = []
os_tabs = ['tab1-mac', 'tab1-windows', 'tab1-raspbian', 'tab2-raspbian', 'tab3-raspbian',
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
    return {'tab1-mac': 'mac',
            'tab1-windows': 'windows',
            'tab1-raspbian': 'raspbian',
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
    return {'mac': ['mac'],
            'windows': ['windows'],
            'raspbian': ['raspbian'],
            'amzn': ['amzn'],
            'debian': ['debian8', 'debian9'],
            'redhat': ['redhat6', 'redhat7'],
            'ubuntu': ['ubuntu14', 'ubuntu16', 'ubuntu18'],
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

def _cmd_run(cmd_args):
    '''
    Runs the given command in a subprocess and returns a dictionary containing
    the subprocess pid, retcode, stdout, and stderr.
    cmd_args
        The list of program arguments constructing the command to run.
    '''
    ret = {}
    try:
        proc = subprocess.Popen(
            cmd_args,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT
        )
    except (OSError, ValueError) as exc:
        ret['stdout'] = str(exc)
        ret['stderr'] = ''
        ret['retcode'] = 1
        ret['pid'] = None
        return ret

    ret['stdout'], ret['stderr'] = proc.communicate()
    ret['pid'] = proc.pid
    ret['retcode'] = proc.returncode
    return ret

def _download_url(url, path):
    print('Downloading url {0} to path: {1}'.format(url, path))
    get_url = requests.get(url, stream=True)
    with open(path, 'wb') as f:
        for chunk in get_url.iter_content(chunk_size=1024):
            if chunk:
                f.write(chunk)

def _get_url(url, md5=False):
    if md5:
        # download urls
        pkg = os.path.join(tempfile.gettempdir(), url.split('/')[-1:][0])
        md5 = pkg + '.md5'
        _download_url(url, path=pkg)
        _download_url(url + '.md5', path=md5)

        # check hashes
        pkg_hash = hashlib.md5(open(pkg,'rb').read()).hexdigest()
        print('comparing hashes for {0} and {1}'.format(pkg, md5))
        with open(md5, 'rt', encoding='utf_16') as f:
            md5_hash = f.read().split()[0].lower()
        try:
            assert md5_hash == pkg_hash
        except AssertionError as e:
            print('the pkg hash: {0} does not match the md5 file: {1}'.format(pkg_hash, md5_hash))
            [os.remove(x) for x in [pkg, md5]]
            raise
        [os.remove(x) for x in [pkg, md5]]

    else:
        print('Querying url: {0}'.format(url))
        get_url = requests.get(url)
        if get_url.status_code != 200:
            raise Exception('url {0} did not return 200'.format(url))
        return get_url

def _get_dependencies(url):
    version = args.salt_version.replace('.', '_')
    os = url.split('/')[5]
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

def _verify_rpm(url, branch):
    rpm = os.path.join(tempfile.gettempdir(),
                       url.split('/')[-1:][0])
    _download_url(url, rpm)
    print('Installing rpm: {0}'.format(url))
    ret = _cmd_run(['yum', 'install', rpm, '-y'])

    # verify repo file
    yum_file = '/etc/yum.repos.d/salt-{0}{1}{2}.repo'.format('py3-' if 'py3' in url else '', 'amzn-' if 'amzn' in url else '', branch)
    with open(yum_file, 'rt') as f:
        repo_file = f.read()
    py_msg = 'for '
    py_pkg = ''

    if 'repo-' in url and '2017' not in args.branch:
        if 'py3' in url:
            if '2018.3' in url:
                py_msg = 'for Python 3 '
            else:
                py_msg = 'Python 3 for '
            py_pkg = 'py3-'
        elif 'latest' not in url:
            py_msg = 'for Python 2 '

    repo_ret = ("[salt-{0}]\n"
            "name=SaltStack {1} Release Channel {3}RHEL/Centos $releasever\n"
            "baseurl=https://repo.saltstack.com/{5}/redhat/{2}/$basearch/{4}\n"
            "failovermethod=priority\n"
            "enabled=1\n"
            "gpgcheck=1\n"
            "gpgkey=file:///etc/pki/rpm-gpg/saltstack-signing-key\n").format(py_pkg + branch,
                                                                             'Latest' if branch == 'latest' else branch,
                                                                             list(os_v)[-1:][0],
                                                                             py_msg,
                                                                             branch,
                                                                             'py3' if 'py3' in url else 'yum')
    if 'amzn' in url:
        repo_ret = ("[salt-amzn-{0}]\n"
                "name=SaltStack {1} Release Channel for native Amazon Linux\n"
                "baseurl=https://repo.saltstack.com/yum/amazon/$releasever/$basearch/{0}\n"
                "failovermethod=priority\n"
                "priority=10\n"
                "enabled=1\n"
                "gpgcheck=1\n"
                "gpgkey=file:///etc/pki/rpm-gpg/saltstack-signing-key\n").format(branch, 'Latest' if branch == 'latest' else branch, list(os_v)[-1:][0])
    if not repo_file == repo_ret:
        raise Exception('{0} and {1} are not matching'.format(repo_file, repo_ret))

    # verify gpg key
    installed_key = '/etc/pki/rpm-gpg/saltstack-signing-key'
    with open(installed_key, 'rt') as f:
        gpg_file = f.read()
    _cmd_run(['rpm', '--import', installed_key])
    gpg_ret = _cmd_run(['rpm', '-qa', 'gpg-pubkey*'])['stdout'].decode()
    if 'gpg-pubkey-de57bfbe-53a9be98' not in gpg_ret:
        raise Exception('saltstacks key: gpg-pubkey-de57bfbe-53a9be98 not found in installed keys')

    # remove rpm
    _cmd_run(['yum', 'remove', '.'.join(rpm.split('/')[-1:][0].split('.')[:-1]), '-y'])


def download_check(urls, salt_version, os_test, branch=None):
    '''
    helper method that will clean up the steps for automation
    '''
    for url in urls:
        if args.staging:
            a_num = 8 if 'https' in url else 7
            auth = url[:a_num] + args.user + ':' + args.passwd + '@' + url[a_num:]
            num = 29 if 'https' in url else 28
            a_len = len(args.user) + len(args.passwd) + num
            url = auth[:a_len] + 'staging/' + auth[a_len:]
        if 'KEY' in url:
            _get_url(url)
        elif not any(x in url for x in ['windows', 'osx']):
            pkgs = []
            if 'apt' in url:
                pkg_format = '_'
                pkgs.append('salt-common{0}{1}'.format(pkg_format, salt_version))
            if any(x in url for x in ['redhat', 'amazon']):
                if 'rpm' in url:
                    _verify_rpm(url, branch)
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
        else:
            pkg = _get_url(url, md5=True if 'md5' not in url else False)

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
    parse_html = bsoup(html, "html.parser")

    # for loop over all tags and find http urls
    for tag in parse_html.findAll(attrs={'id' : tab_os}):
        for tab_os_v in tag.findAll(attrs={'class': re.compile(os_v + ".*")}):
            for cmd in tab_os_v.findAll(attrs={'class': 'language-bash'}):
                _add_urls(cmd)
            for cmd_2 in tab_os_v.findAll(attrs={'class': 'language-ini'}):
                _add_urls(cmd_2)
            for cmd_3 in tab_os_v.findAll('a', href=True):
                _add_urls(cmd_3)
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
