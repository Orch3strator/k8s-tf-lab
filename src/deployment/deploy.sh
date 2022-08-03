#!/bin/bash
# shellcheck enable=require-variable-braces
# file name: deploy.sh
################################################################################
# License                                                                      #
################################################################################
function license() {
    # On MAC update bash: https://scriptingosx.com/2019/02/install-bash-5-on-macos/
    printf '%s\n' ""
    printf '%s\n' " GPL-3.0-only or GPL-3.0-or-later"
    printf '%s\n' " Copyright (c) 2021 BMC Software, Inc."
    printf '%s\n' " Author: Volker Scheithauer"
    printf '%s\n' " E-Mail: orchestrator@bmc.com"
    printf '%s\n' ""
    printf '%s\n' " This program is free software: you can redistribute it and/or modify"
    printf '%s\n' " it under the terms of the GNU General Public License as published by"
    printf '%s\n' " the Free Software Foundation, either version 3 of the License, or"
    printf '%s\n' " (at your option) any later version."
    printf '%s\n' ""
    printf '%s\n' " This program is distributed in the hope that it will be useful,"
    printf '%s\n' " but WITHOUT ANY WARRANTY; without even the implied warranty of"
    printf '%s\n' " MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the"
    printf '%s\n' " GNU General Public License for more details."
    printf '%s\n' ""
    printf '%s\n' " You should have received a copy of the GNU General Public License"
    printf '%s\n' " along with this program.  If not, see <https://www.gnu.org/licenses/>."
}

# Get current script folder
DIR_NAME=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
SCRIPT_SETTINGS="${DIR_NAME}/config/setup.settings.ini"
SCRIPT_DATA_FILE="${DIR_NAME}/config/data.json"

# import bash colors
if [[ -f "${SCRIPT_SETTINGS}" ]]; then
    source <(grep = "${SCRIPT_SETTINGS}")
fi

# Script defaults
retcode=0
SETUP_DIR="${DIR_NAME}"
SUDO_STATE="false"

# hostname is assumed to be a FQDN set during installation.
# shellcheck disable=SC2006 disable=SC2086# this is intentional
HOST_FQDN=$(cat /etc/hostname)
# shellcheck disable=SC2006 disable=SC2086# this is intentional
HOST_NAME=$(echo ${HOST_FQDN} | awk -F "." '{print $1}')
# shellcheck disable=SC2006 disable=SC2086# this is intentional
DOMAIN_NAME=$(echo ${HOST_FQDN} | awk -F "." '{print $2"."$3}')
# shellcheck disable=SC2006 disable=SC2086# this is intentional
HOST_IPV4=$(ip address | grep -v "127.0.0" | grep "inet " | awk '{print $2}' | awk -F "/" '{print $1}')

DATE_TODAY="$(date '+%Y-%m-%d %H:%M:%S')"
LOG_DATE=$(date +%Y%m%d.%H%M%S)
LOG_DIR="${SETUP_DIR}/logs"
# shellcheck disable=SC2006 disable=SC2086# this is intentional
LOG_NAME=$(basename $0)
LOG_FILE="${LOG_DIR}/${LOG_NAME}.${LOG_DATE}.txt"
SCRIPT_NAME="${LOG_NAME}"

SCRIPT_PURPOSE="user and group setup"

# Show license
license

terraform destroy -auto-approve
terraform plan -out k8s
terraform apply k8s
