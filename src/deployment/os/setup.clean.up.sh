#!/bin/bash
# shellcheck enable=require-variable-braces
# file name: setup.clean.up.sh
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
USER_VIMRC_FILE="${DIR_NAME}/vimrc"

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
LOG_DIR="/mnt/client/data/logs/${HOST_NAME}"

# shellcheck disable=SC2006 disable=SC2086# this is intentional
LOG_NAME=$(basename $0)
LOG_FILE="${LOG_DIR}/${LOG_NAME}.log"
SCRIPT_NAME="${LOG_NAME}"

# keep track of deployment status
STATUS_FILE_PREFIX="${LOG_DIR}/${LOG_NAME}"

# Linux Distribution
DISTRIBUTION=$(sudo cat /etc/*-release | uniq -u | grep "^NAME" | awk -F "=" '{ gsub("\"", "",$2); print $2}')
DISTRIBUTION_PRETTY_NAME=$(sudo cat /etc/*-release | uniq -u | grep "^PRETTY_NAME" | awk -F "=" '{ gsub("\"", "",$2); print $2}')

SCRIPT_PURPOSE="clean-up installation and resources"

# Show license
license

if [[ "${EUID}" = 0 ]]; then
    # create log dir
    if [ ! -d "${LOG_DIR}" ]; then
        sudo mkdir -p "${LOG_DIR}"
    fi
    sudo sh -c "echo ' -----------------------------------------------' >> '${LOG_FILE}'"
    sudo sh -c "echo ' Start date: ${DATE_TODAY}' >> '${LOG_FILE}'"
    sudo sh -c "echo ' User Name : ${USER}' >> '${LOG_FILE}'"
    sudo sh -c "echo ' Host FDQN : ${HOST_FQDN}' >> '${LOG_FILE}'"
    sudo sh -c "echo ' Host Name : ${HOST_NAME}' >> '${LOG_FILE}'"
    sudo sh -c "echo ' Host IPv4 : ${HOST_IPV4}' >> '${LOG_FILE}'"
    SUDO_STATE="true"
else
    echo " -----------------------------------------------"
    echo -e "${Color_Off} Setup Procedure for            : ${Cyan}${SCRIPT_PURPOSE}${Color_Off}"
    echo -e "${Color_Off} This procedure needs to run as : ${BRed}root${Color_Off}"
    echo -e "${BRed} sudo ${Cyan}${SCRIPT_NAME}${Color_Off}"
    echo " -----------------------------------------------"
    retcode=1
    exit
fi

echo " "
echo " Manage System Packages"
echo " -----------------------------------------------"
echo -e " ${Cyan}Date         : ${Yellow}${DATE_TODAY}${Color_Off}"
echo -e " ${Cyan}Distribution : ${Yellow}${DISTRIBUTION_PRETTY_NAME}${Color_Off}"
echo -e " ${Cyan}Current User : ${Yellow}${USER}${Color_Off}"
echo -e " ${Cyan}Sudo Mode    : ${Yellow}${SUDO_STATE}${Color_Off}"
echo -e " ${Cyan}Domain Name  : ${Yellow}${DOMAIN_NAME}${Color_Off}"
echo -e " ${Cyan}Host FDQN    : ${Yellow}${HOST_FQDN}${Color_Off}"
echo -e " ${Cyan}Host Name    : ${Yellow}${HOST_NAME}${Color_Off}"
echo -e " ${Cyan}Host IPv4    : ${Yellow}${HOST_IPV4}${Color_Off}"
echo -e " ${Cyan}Data File    : ${Yellow}${SCRIPT_DATA_FILE}${Color_Off}"

echo " -----------------------------------------------"
SCRIPT_ACTION="clean-up installation"
echo -e " Script Status: ${Purple}${SCRIPT_ACTION}${Color_Off}"

# keep track of deployment status
STATUS_STEP="main"
STATUS_FILE="${STATUS_FILE_PREFIX}.${STATUS_STEP}.txt"

if [[ ! -f "${STATUS_FILE}" ]]; then
    if [[ -f "${SCRIPT_DATA_FILE}" ]]; then
        SCRIPT_DATA=$(jq '.' "${SCRIPT_DATA_FILE}")

        SCRIPT_ACTION="Control-M Setup - Clean Up: Start"
        echo -e " Script Status: ${Purple}${SCRIPT_ACTION}${Color_Off}"

        # get default password
        USER_DEFAULT_PWD=$(echo "${SCRIPT_DATA}" | jq -r '.USERS.PWD')
        # get ssh rsa authorized_keys
        USER_AUTH_SSH_KEY=$(echo "${SCRIPT_DATA}" | jq -r '.USERS.RSA')

        # extract all users
        while IFS= read -r obj; do
            # echo "JSON Key: ${obj}"
            USER_NAME=$(echo "${obj}" | jq -r '.name')
            USER_PURPOSE=$(echo "${obj}" | jq -r '.purpose')
            USER_SHELL=$(echo "${obj}" | jq -r '.shell')
            USER_BASE=$(echo "${obj}" | jq -r '.base')
            USER_ID=$(echo "${obj}" | jq -r '.id')
            USER_TITLE=$(echo "${obj}" | jq -r '.title')
            USER_GROUP_PRIMARY=$(echo "${obj}" | jq -r '.group')
            USER_GROUPS=$(echo "${obj}" | jq -r '.groups')
            IFS=',' read -ra USER_GROUP_LIST <<<"${USER_GROUPS}"

            echo " ---- "

            # log user details
            sudo sh -c "echo ' -------------' >> '${LOG_FILE}'"
            sudo sh -c "echo ' User Name  : ${USER_NAME}' >> '${LOG_FILE}'"
            sudo sh -c "echo ' User Title : ${USER_TITLE}' >> '${LOG_FILE}'"
            sudo sh -c "echo ' Purpose    : ${USER_PURPOSE}' >> '${LOG_FILE}'"
            sudo sh -c "echo ' User Shell : ${USER_SHELL}' >> '${LOG_FILE}'"
            sudo sh -c "echo ' User Home  : ${USER_BASE}/${USER_NAME}' >> '${LOG_FILE}'"
            sudo sh -c "echo ' User ID    : ${USER_ID}' >> '${LOG_FILE}'"

            # remove onlt ctm resources
            if [[ "${USER_NAME}" == *ctm* ]]; then
                echo -e "${Color_Off} = ${Cyan}Process   :${Color_Off} '${USER_NAME}'${Color_Off}"
                # check if user exists
                if id "${USER_NAME}" >/dev/null 2>&1; then
                    echo -e "${Color_Off} = ${Cyan}Status    :${Color_Off} '${USER_NAME}' ${Red}user exists${Color_Off}"
                    sudo killall -u "${USER_NAME}"
                    sudo userdel --force --remove "${USER_NAME}"
                fi

                # check if user group exists
                if [ "$(getent group ${USER_GROUP_PRIMARY})" ]; then
                    echo -e "${Color_Off} = ${Cyan}Status    :${Color_Off} '${USER_GROUP_PRIMARY}' ${Red}group exists${Color_Off}"
                    sudo groupdel "${USER_GROUP_PRIMARY}"
                fi

                # check if user home exists
                if [[ -d "${USER_BASE}/${USER_NAME}" ]]; then
                    echo -e "${Color_Off} = ${Cyan}Status    :${Color_Off} '${USER_NAME}' ${Red}home exists${Color_Off}"
                    sudo rm "${USER_BASE}/${USER_NAME}" -Rf
                fi
            fi

            # clean-up log files
            if [ -d "${LOG_DIR}" ]; then
                sudo rm "${LOG_DIR}/*.txt" -Rf
            fi

            sudo sh -c "echo ' -------------' >> '${LOG_FILE}'"

        done \
            < <(echo "${SCRIPT_DATA}" | jq -r '.USERS.OS' | jq -c '.[]')

        sudo touch ${LOG_DIR}/setup.clean.up.txt
    fi

    SCRIPT_ACTION="Control-M Setup - Clean Up: systemd"
    echo -e " Script Status: ${Purple}${SCRIPT_ACTION}${Color_Off}"
    sudo sh -c "echo ' SCRIPT_ACTION : ${SCRIPT_ACTION}' >> '${LOG_FILE}'"

    # clean-up ctm stuff
    if [[ -f "/etc/systemd/system/ctmsrv.service" ]]; then
        sudo rm /etc/systemd/system/ctmsrv* -Rf
    fi

    if [[ -f "/etc/systemd/system/ctmem.service" ]]; then
        sudo rm /etc/systemd/system/ctmem* -Rf
    fi

    if [[ -f "/etc/systemd/system/ctmagt.service" ]]; then
        sudo rm /etc/systemd/system/ctmagt* -Rf
    fi

    if [[ -f "/etc/systemd/system/ctmgtw.service" ]]; then
        sudo rm /etc/systemd/system/ctmgtw* -Rf
    fi

    if [[ -f "/etc/systemd/system/ctmwi.service" ]]; then
        sudo rm /etc/systemd/system/ctmwi* -Rf
    fi

    if [[ -f "/etc/systemd/system/ctmarch.service" ]]; then
        sudo rm /etc/systemd/system/ctmarch* -Rf
    fi

    sudo systemctl daemon-reload

    SCRIPT_ACTION="Control-M Setup - Clean Up: OS"
    echo -e " Script Status: ${Purple}${SCRIPT_ACTION}${Color_Off}"
    sudo sh -c "echo ' SCRIPT_ACTION : ${SCRIPT_ACTION}' >> '${LOG_FILE}'"

    # clean up os stuff
    if [[ -f "/etc/sudoers.d/${DOMAIN_NAME}" ]]; then
        sudo rm /etc/sudoers.d/${DOMAIN_NAME} -Rf
    fi

    SCRIPT_ACTION="Control-M Setup - Clean Up: End"
    echo -e " Script Status: ${Purple}${SCRIPT_ACTION}${Color_Off}"
    sudo sh -c "echo ' SCRIPT_ACTION : ${SCRIPT_ACTION}' >> '${LOG_FILE}'"

    # keep track of deployment status
    STATUS_STEP="main"
    STATUS_FILE="${STATUS_FILE_PREFIX}.${STATUS_STEP}.txt"
    sudo touch "${STATUS_FILE}"
else
    SCRIPT_ACTION=" - nothing to do"
    echo -e " Script Status: ${Yellow}${SCRIPT_ACTION}${Color_Off}"
    sudo sh -c "echo ' SCRIPT_ACTION : ${SCRIPT_ACTION}' >> '${LOG_FILE}'"

fi
