#!/usr/bin/env python

#import python modules
import optparse
import requests
import sys


def get_args():
    parser = optparse.OptionParser()
    parser.add_option("-o", "--os-version",
                      help="Specify os version")
    parser.add_option("-d", "--os-dist",
                      help="Specify os distribution. For example redhat")
    parser.add_option("-v", "--salt-version",
                      help="Specify the version of salt")
    parser.add_option("-s", "--staging",
                      action="store_true",
                      help="Specify the version of salt")
    return parser

def get_url(release, os_version, salt_version, os_dist, staging):
    if 'redhat' in os_dist.lower():
        url_dist = 'yum/redhat/'
    if staging:
        root_url = 'https://repo.saltstack.com/staging/'
    else:
        root_url = 'https://repo.saltstack.com/'
    branch = salt_version.rsplit('.', 1)[0]
    release_map = {
        'latest': 'latest',
        'major': branch,
        'minor': 'archive/' + salt_version,
    }

    release_type = release_map.get(release)

    url = root_url + url_dist + os_version + '/x86_64/' + release_type + '/base/'
    return url

def check_url(url):
    r = requests.get(url)
    contents = r.text
    status = r.status_code

    dependencies = ['babel', 'libyaml', 'pciutils', 'pciutils-devel',
                    'pciutils-devel-static', 'pciutils-libs', 'python-babel',
                    'python-chardet', 'python-jinja2', 'python-kitchen',
                    'python-kitchen-doc', 'python-markupsafe',
                    'python-requests', 'python-six', 'python-urllib',
                    'yum-utils']
    for dependency in dependencies:
        if dependency not in contents:
            print('The dependency {0} from the url {1} is not \
                  available.'.format(dependency, url))
            return False
    return True

def main():
    parser = get_args()
    (args, options) = parser.parse_args()

    failure = []
    releases = ['latest', 'major', 'minor']

    for release in releases:
        url = get_url(release, args.os_version, args.salt_version,
                      args.os_dist, args.staging)
        url_status = check_url(url)
        if not url_status:
            failure.append(url)

    if failure:
        for failed_url in failure:
            print('The following url failed: {0}'.format(failed_url))
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == '__main__':
    main()
