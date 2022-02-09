#!/usr/bin/env sh
# Fetch Ansible requirements
set -eu

if test -e requirements.yml; then
    apk add \
        ansible \
        git

    ansible-galaxy role install \
        -r requirements.yml
    ansible-galaxy collection install \
        -r requirements.yml
fi
