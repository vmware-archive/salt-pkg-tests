#!/bin/bash

check_systemd_config() {
    config=$1
    expected_return=$2
    cmd=`systemctl show -p ${config} salt-minion.service`
    if [ ${cmd} == "${config}=${expected_return}" ]; then
            echo "${config} is set correctly to ${expected_return}"
    else
            (>&2 echo "${config} is not set correctly to ${expected_return}")
            exit 1
    fi
}

SYSTEMD_CMD='systemctl'
if type "${SYSTEMD_CMD}" > /dev/null; then
    check_systemd_config KillMode control-group
    check_systemd_config Type notify
else
    (>&2 echo "systemctl does not exist. systemd is not on this vm. SKIPPING TEST")
fi
