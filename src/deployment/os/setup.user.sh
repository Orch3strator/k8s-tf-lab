#!/bin/bash
# shellcheck enable=require-variable-braces
# file name: setup.user.sh
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

SCRIPT_PURPOSE="user and group setup"

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
SCRIPT_ACTION="user management"
echo -e " Script Status: ${Purple}${SCRIPT_ACTION}${Color_Off}"

# keep track of deployment status
STATUS_STEP="main"
STATUS_FILE="${STATUS_FILE_PREFIX}.${STATUS_STEP}.txt"

if [[ ! -f "${STATUS_FILE}" ]]; then
    if [[ -f "${SCRIPT_DATA_FILE}" ]]; then
        SCRIPT_DATA=$(jq '.' "${SCRIPT_DATA_FILE}")

        # extract all groups
        while IFS= read -r obj; do
            # echo "JSON Key: ${obj}"
            GROUP_NAME=$(echo "${obj}" | jq -r '.name')
            GROUP_PURPOSE=$(echo "${obj}" | jq -r '.purpose')
            GROUP_ID=$(echo "${obj}" | jq -r '.id')

            echo " ---- "
            echo -e " ${Cyan}Group Name  : ${Color_Off}${GROUP_NAME}"
            # echo -e " ${Cyan}Purpose     : ${Color_Off}${GROUP_PURPOSE}"
            # echo -e " ${Cyan}Group ID    : ${Color_Off}${GROUP_ID}"

            # check if user group exists
            if [ "$(getent group ${GROUP_NAME})" ]; then
                echo -e "${Color_Off} = ${Cyan}Status    :${Color_Off} ${Green}group exists${Color_Off}"
            else

                echo -e "${Color_Off} + ${Cyan}Status    :${Color_Off} ${IYellow}creating${Color_Off}"
                OS_CMD="sudo groupadd -g ${GROUP_ID} ${GROUP_NAME}"
                echo -e "${Color_Off} - ${Cyan}OS Cmd    :${Color_Off} ${IRed}${OS_CMD}${Color_Off}"

                OS_CMD="sudo usermod -aG ${GROUP_NAME} root"
                echo -e "${Color_Off} - ${Cyan}OS Cmd    :${Color_Off} ${IRed}${OS_CMD}${Color_Off}"

                sudo groupadd -g "${GROUP_ID}" "${GROUP_NAME}"
                sudo usermod -aG "${GROUP_NAME}" root
                echo "%${GROUP_NAME} ALL=(ALL)    NOPASSWD: ALL" | sudo tee -a /etc/sudoers.d/${DOMAIN_NAME}
            fi
        done < <(echo "${SCRIPT_DATA}" | jq -r '.GROUPS.OS' | jq -c '.[]')

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
            echo -e " ${Cyan}User Name   : ${Color_Off}${USER_NAME}"
            # echo -e " ${Cyan}User Pwd    : ${Color_Off}${USER_DEFAULT_PWD}"
            # echo -e " ${Cyan}User Title : ${Color_Off}${USER_TITLE}"
            # echo -e " ${Cyan}Purpose    : ${Color_Off}${USER_PURPOSE}"
            # echo -e " ${Cyan}User Shell : ${Color_Off}${USER_SHELL}"
            # echo -e " ${Cyan}User Home  : ${Color_Off}${USER_BASE}/${USER_NAME}"
            # echo -e " ${Cyan}User ID    : ${Color_Off}${USER_ID}"
            # echo -e " ${Cyan}VIM Settings: ${Color_Off}${USER_VIMRC_FILE}"

            # log user details
            sudo sh -c "echo ' -------------' >> '${LOG_FILE}'"
            sudo sh -c "echo ' User Name  : ${USER_NAME}' >> '${LOG_FILE}'"
            sudo sh -c "echo ' User Title : ${USER_TITLE}' >> '${LOG_FILE}'"
            sudo sh -c "echo ' Purpose    : ${USER_PURPOSE}' >> '${LOG_FILE}'"
            sudo sh -c "echo ' User Shell : ${USER_SHELL}' >> '${LOG_FILE}'"
            sudo sh -c "echo ' User Home  : ${USER_BASE}/${USER_NAME}' >> '${LOG_FILE}'"
            sudo sh -c "echo ' User ID    : ${USER_ID}' >> '${LOG_FILE}'"

            # check if user group exists
            if [ "$(getent group "${USER_GROUP_PRIMARY}")" ]; then
                echo -e "${Color_Off} = ${Cyan}Status    :${Color_Off} '${USER_GROUP_PRIMARY}' ${Green}group exists${Color_Off}"

                # check if user exists
                if id "${USER_NAME}" >/dev/null 2>&1; then
                    echo -e "${Color_Off} = ${Cyan}Status    :${Color_Off} '${USER_NAME}' ${Green}user exists${Color_Off}"
                    if [[ -f "${USER_VIMRC_FILE}" ]]; then
                        shopt -s dotglob
                        sudo cp "${USER_VIMRC_FILE}" "${USER_BASE}/${USER_NAME}/.vimrc"
                        sudo chown -R "${USER_NAME}:${USER_NAME}" "${USER_BASE}/${USER_NAME}"
                        sudo chmod -R 0700 "${USER_BASE}/${USER_NAME}"
                        shopt -u dotglob
                    fi
                else
                    echo -e "${Color_Off} + ${Cyan}${USER_NAME}${Color_Off}: ${Red}creating${Color_Off}"
                    OS_CMD="sudo useradd -c '"${USER_TITLE}"' -G ${USER_GROUP} -u ${USER_ID} ${USER_NAME} -m -d ${USER_BASE}/${USER_NAME} -s ${USER_SHELL}"
                    echo -e "${Color_Off} - ${Cyan}OS Cmd  :${Color_Off} ${IRed}${OS_CMD}${Color_Off}"

                    sudo useradd -c '"${USER_TITLE}"' -G "${USER_GROUP}" -u "${USER_ID}" "${USER_NAME}" -m -d "${USER_BASE}/${USER_NAME}" -s "${USER_SHELL}"
                    USER_DEFAULT_PWD_SHA256=$(echo "${USER_DEFAULT_PWD}" | /usr/bin/sha256sum | awk '{print $1}')
                    echo "${USER_NAME}:${USER_DEFAULT_PWD}" | chpasswd
                    sudo mkdir -p "${USER_BASE}/${USER_NAME}"/.ssh
                    sudo ssh-keygen -o -t rsa -b 4096 -C ${USER_NAME}@${DOMAIN_NAME} -q -f "${USER_BASE}/${USER_NAME}/.ssh/id_rsa" -N ""
                    sudo echo "${USER_AUTH_SSH_KEY}" >>"${USER_BASE}/${USER_NAME}/.ssh/authorized_keys"
                    sudo chmod 700 "${USER_BASE}/${USER_NAME}/.ssh"
                    sudo chmod 600 "${USER_BASE}/${USER_NAME}/.ssh/authorized_keys"
                    sudo chown -R "${USER_NAME}":"${USER_NAME}" "${USER_BASE}/${USER_NAME}"

                    if [[ -f "${USER_VIMRC_FILE}" ]]; then
                        shopt -s dotglob
                        sudo cp "${USER_VIMRC_FILE}" "${USER_BASE}/${USER_NAME}/.vimrc"
                        sudo chown -R "${USER_NAME}:${USER_NAME}" "${USER_BASE}/${USER_NAME}"
                        sudo chmod -R 0700 "${USER_BASE}/${USER_NAME}"
                        shopt -u dotglob
                    fi

                fi

                for USER_GROUP in "${USER_GROUP_LIST[@]}"; do
                    echo -e " ${Cyan}User Group  : ${Color_Off}"
                    sudo usermod -aG "${USER_GROUP}" "${USER_NAME}"

                    # log user details
                    sudo sh -c "echo ' User Group : ${USER_GROUP}' >> '${LOG_FILE}'"
                done

            else
                echo -e "${Color_Off} = ${Cyan}Status    :${Color_Off} primary user group ${IYellow}'${USER_GROUP_PRIMARY}' ${Color_Off}for user ${IYellow}'${USER_NAME}'${Color_Off} does not exist.${Color_Off}"
            fi
            # log user details
            sudo sh -c "echo ' -------------' >> '${LOG_FILE}'"

            # Sudoers User
            #if [[ ! -f "${SETUP_DIR}/setup.check.sudoers.user.${USER_NAME}.txt" ]]; then
            #    echo -e "${USER_NAME}\tALL=(ALL:ALL)\tNOPASSWD: ALL" | sudo tee -a /etc/sudoers.d/${DOMAIN_NAME}
            #    sudo usermod -aG wheel "${USER_NAME}"
            #    touch ${SETUP_DIR}/setup.check.sudoers.user.${USER_NAME}.txt
            #fi

            # Sudoers Group
            # keep track of deployment status
            STATUS_STEP="sudoers"
            STATUS_FILE="${STATUS_FILE_PREFIX}.${STATUS_STEP}.${USER_GROUP_PRIMARY}.txt"
            if [[ ! -f "STATUS_FILE" ]]; then
                echo -e "%${USER_GROUP_PRIMARY}\tALL=(ALL)\tNOPASSWD: ALL" | sudo tee -a /etc/sudoers.d/${DOMAIN_NAME}
                sudo touch "${STATUS_FILE}"
            fi

            sudo chmod 0600 /etc/sudoers.d/${DOMAIN_NAME}
            sudo sudo chown root:root /etc/sudoers.d/${DOMAIN_NAME}

        done \
            < <(echo "${SCRIPT_DATA}" | jq -r '.USERS.OS' | jq -c '.[]')
    fi

    # keep track of deployment status
    STATUS_STEP="main"
    STATUS_FILE="${STATUS_FILE_PREFIX}.${STATUS_STEP}.txt"
    sudo touch "${STATUS_FILE}"
else
    SCRIPT_ACTION=" - nothing to do"
    echo -e " Script Status: ${Yellow}${SCRIPT_ACTION}${Color_Off}"
    sudo sh -c "echo ' SCRIPT_ACTION : ${SCRIPT_ACTION}' >> '${LOG_FILE}'"
fi
