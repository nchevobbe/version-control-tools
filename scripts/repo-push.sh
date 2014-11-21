#!/bin/bash

ppid=$$
sshargs="-i /etc/mercurial/mirror -o ServerAliveInterval=5 -o ConnectionAttempts=3 -o StrictHostKeyChecking=no -o ConnectTimeout=10s -o PasswordAuthentication=no -o PreferredAuthentications=publickey -o UserKnownHostsFile=/etc/mercurial/known_hosts"

pulltrigger() {
    _args=$*
    /usr/bin/ssh -l hg ${sshargs} ${HOST} -- "${_args}" 2>&1 | \
        /usr/bin/logger -t "repo-push.sh[${ppid}] ${_args} to ${HOST} for ${SUDO_USER}"
    res=${PIPESTATUS[0]}
    if [ ${res} != 0 ]; then
    /usr/bin/logger -t "repo-push.sh[${ppid}] ssh returned ${res}, retrying ${_args} to ${HOST} for ${SUDO_USER}"
        sleep 1
    /usr/bin/ssh -l hg ${sshargs} ${HOST} -- "${_args}" 2>&1 | \
            /usr/bin/logger -t "repo-push.sh[${ppid}] retry ${_args} to ${HOST} for ${SUDO_USER}"
    fi
}

for HOST in $(cat /etc/mercurial/mirrors)
do
    pulltrigger $* &
done
wait

