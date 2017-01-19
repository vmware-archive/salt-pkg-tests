#!/usr/bin/python
from BeautifulSoup import BeautifulSoup as bsoup
import BeautifulSoup
from shutil import copyfile
import argparse
import requests
import re
import os



# Miscellaneous variables
TMP_DOCKER_DIR = os.path.join('/tmp', 'docker')
LATEST = '2016.11'

check_steps = []
os_tabs = ['tab1-debian', 'tab2-debian', 'tab3-debian', 'tab1-redhat',
           'tab2-redhat', 'tab3-redhat', 'tab1-ubuntu', 'tab2-ubuntu',
           'tab3-ubuntu']

def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-b', '--branch',
        help='Specific salt branch. Ex. 2016.3'
    )

    return parser

def det_os_family(os):
    return {'tab1-debian': 'debian',
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
    return {'debian': ['debian7', 'debian8'],
            'redhat': ['redhat5', 'redhat6', 'redhat7'],
            'ubuntu': ['ubuntu12', 'ubuntu14', 'ubuntu16'],
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

def sanitize_steps(step, os_v):
    '''
    helper method that will clean up the steps for automation
    '''
    remove_steps = ['restart', 'saltstack.list', 'yum.repos.d/saltstack.repo',
                   'python-', 'systemd', '[Service', 'Killmode']
    text = (''.join(step.findAll(text=True)))

    if 'install' in text:
        text = text + ' -y'
    elif 'deb http' in text:
        text = "echo \'" + text + "\' > /etc/apt/sources.list.d/salt_test.list"
        {% if staging %}
        text = text + '; sed -i \'s/com\/apt/com\/staging\/apt/\' /etc/apt/sources.list.d/salt*.list'
        {% endif %}

    if 'redhat' in os_v:
        if 'yum install http' in text:
            {% if staging %}
            text = text + '; sed -i \'s/com\/yum/com\/staging\/yum/\' /etc/yum.repos.d/salt*.repo'
            {% endif %}
            pass
        if 'saltstack-repo' in text:
            text = "echo \'" + text + "\' > /etc/yum.repos.d/salt.repo"
            {% if staging %}
            text = text + '; sed -i \'s/com\/yum/com\/staging\/yum/\' /etc/yum.repos.d/salt*.repo'
            {% endif %}

    add_step = True
    for rm in remove_steps:
        if rm in text:
            add_step = False
    if add_step == True and text not in check_steps:
        check_steps.append(text)


def parse_html_method(tab_os, os_v, args):
    '''
    Parse the index.html for install commands
    '''
    # Get and Parse url variables
    if args.branch != LATEST:
        url = 'https://repo.saltstack.com/staging/{0}.html'.format(args.branch)
    else:
        url = 'https://repo.saltstack.com/staging/index.html'.format()

    get_url = requests.get(url)
    html = get_url.content
    parse_html = bsoup(html)

    os_instruction = []

    for tag in parse_html.findAll(attrs={'id' : tab_os}):
        # grab all instructions for a specific os and release
        # for example grab debian7 for latest release
        for tab_os_v in tag.findAll(attrs={'class': re.compile(os_v + ".*")}):
            for cmd in tab_os_v.findAll(attrs={'class': 'language-bash'}):
                if cmd not in os_instruction:
                    os_instruction.append(cmd)
            for cmd_2 in tab_os_v.findAll(attrs={'class': 'language-ini'}):
                if cmd_2 not in os_instruction:
                    os_instruction.append(cmd_2)
        # get all instructions that run on both veresion of each os_family
        for cmd_all in tag.findAll('code', attrs={'class': None}):
            if cmd_all not in os_instruction:
                os_instruction.append(cmd_all)
    return os_instruction


def write_to_file(current_os, steps, release, os_v, salt_branch):
    '''
    Write installation instructions to Dockerfile
    '''
    distro=current_os.split('-')[1]
    docker_dir=os.path.join(TMP_DOCKER_DIR, salt_branch, os_v, release)
    docker_file=os.path.join(docker_dir, "install_salt.sh")

    if not os.path.exists(docker_dir):
        os.makedirs(docker_dir)

    for step in steps:
        sanitize_steps(step, os_v)
    with open(docker_file, 'w') as outfile:
        for step in check_steps:
            outfile.write(step)
            outfile.write('\n')

    if 'redhat' in os_v:
        ver = os_v[-1:]
        cent_dockerdir=os.path.join(TMP_DOCKER_DIR, salt_branch, 'centos' + ver, release)
        if not os.path.exists(cent_dockerdir):
            os.makedirs(cent_dockerdir)
        copyfile(docker_file, cent_dockerdir + "/install_salt.sh")
    del check_steps[:]

for current_os in os_tabs:
    parser = get_args()
    args = parser.parse_args()
    os_family = det_os_family(current_os)
    os_versions = det_os_versions(os_family)
    release = determine_release(current_os)
    for os_v in os_versions:
        os_instr = parse_html_method(current_os, os_v, args)
        write_to_file(current_os, os_instr, release, os_v, args.branch)
