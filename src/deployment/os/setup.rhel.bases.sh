#!/bin/bash
# shellcheck enable=require-variable-braces
# file name: setup.rhel.bases.sh
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

SCRIPT_PURPOSE="RHEL Base OS Setup"

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
SCRIPT_ACTION="RHEL Base Setup"
echo -e " Script Status: ${Purple}${SCRIPT_ACTION}${Color_Off}"

PACKAGE_LIST=""
PACKAGES_REQUIRED=(
    "openssl"
    "haveged"
    "rng-tools"
    "resolvconf"
    "nfs-utils"
    "nfs4-acl-tools"
    "python3-pip"
    "python39"
    "software-properties-common"
    "bluez"
    "wireless-tools"
    "unzip"
    "vim-enhanced"
    "htop"
    "iputils-ping"
    "net-tools"
    "NetworkManager"
    "ufw"
    "jq"
    "curl"
    "wget"
    "psmisc"
    "ntpdate"
    "chrony"
    "ntpdate"
    "dnsutils"
    "bind-utils"
    "yum-utils"
    "gdisk"
    "unzip"
    "traceroute"
    "mailx"
    "telnet"
    "sssd"
    "oddjob"
    "oddjob-mkhomedir"
    "adcli"
    "samba-common-tools"
    "krb5-workstation"
    "realmd"
    "epel-release"
    "deltarpm"
    "curl"
    "policycoreutils"
    "python3-policycoreutils"
    "policycoreutils-python-utils"
    "openldap-clients"
    "git"
    "zsh"
    "xterm"
    "xorg-x11-xauth"
    "xorg-x11-fonts-*"
    "xorg-x11-font-utils"
    "xorg-x11-fonts-Type1"
    "nodejs"
    "time"
    "bc"
)

SCRIPT_ACTION="set fqdn"
echo -e " Script Status: ${Purple}${SCRIPT_ACTION}${Color_Off}"
sudo hostnamectl set-hostname "${HOST_NAME}".trybmc.com --static

# keep track of deployment status
STATUS_STEP="main"
STATUS_FILE="${STATUS_FILE_PREFIX}.${STATUS_STEP}.txt"

# Red Hat
if [[ ! -f "${STATUS_FILE}" ]]; then

    if [[ "${DISTRIBUTION}" == *"Red"* ]]; then
        SCRIPT_ACTION="checking subscription"
        echo -e " Script Status: ${Purple}${SCRIPT_ACTION}${Color_Off}"

        SUBSCRIPTION_STATUS=$(sudo subscription-manager status | grep "Overall Status" | awk -F ":" '{print $2}')
        sudo sh -c "echo ' Subscription:${SUBSCRIPTION_STATUS}' >> '${LOG_FILE}'"

        if [[ "${SUBSCRIPTION_STATUS}" == *"Current"* ]]; then

            echo " -----------------------------------------------"
            SCRIPT_ACTION="adding repositories"
            echo -e " Script Status: ${Purple}${SCRIPT_ACTION}${Color_Off}"

            REPO_EPEL_STATUS=$(sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm)
            sudo sh -c "echo ' Repo Status:${REPO_EPEL_STATUS}' >> '${LOG_FILE}'"

            echo " -----------------------------------------------"
            SCRIPT_ACTION="update system"
            echo -e " Script Status: ${Purple}${SCRIPT_ACTION}${Color_Off}"

            DNF_TOOL=$(sudo dnf install dnf-utils -y --quiet)
            UPDATE_STATUS=$(sudo dnf update -y --quiet | awk -F ":" "{print $2}")
            echo " ${UPDATE_STATUS}"

            SCRIPT_ACTION="analyzing packages"
            echo -e " Script Status: ${Purple}${SCRIPT_ACTION}${Color_Off}"
            PACKAGES_INSTALLED=$(sudo dnf repoquery --installed --qf '"%{name}"' 2>/dev/null | awk -F "." "{print $2}")
            PACKAGES_KNOWN=$(sudo dnf repoquery --qf '"%{name}"' 2>/dev/null | awk -F "." "{print $2}")

            sudo sh -c "echo '================================================' >> '${LOG_FILE}'"
            sudo sh -c "echo ' System Packages - Check' >> '${LOG_FILE}'"
            for PACKAGE in "${PACKAGES_REQUIRED[@]}"; do
                # shellcheck disable=SC2046 # this is intentionals
                if [[ "${PACKAGES_INSTALLED}" == *\"${PACKAGE}\"* ]]; then
                    echo -e "${Color_Off} = ${Cyan}${PACKAGE}${Color_Off}: ${Green}installed${Color_Off}"
                    sudo sh -c "echo ' = ${PACKAGE}: installed' >> '${LOG_FILE}'"

                else
                    # Check if package exists
                    # sif $(contains "${PACKAGES_KNOWN}" \"${PACKAGE}\"); then
                    if [[ "${PACKAGES_KNOWN}" == *\"${PACKAGE}\"* ]]; then
                        echo -e "${Color_Off} + ${Cyan}${PACKAGE}${Color_Off}: ${Yellow}available${Color_Off}"
                        sudo sh -c "echo ' + ${PACKAGE}: available' >> '${LOG_FILE}'"
                        PACKAGE_LIST=${PACKAGE_LIST}" "${PACKAGE}
                    else
                        echo -e " - ${PACKAGE}: ${Red}does not exist${Color_Off}"
                        sudo sh -c "echo ' - ${PACKAGE}: does not exist' >> '${LOG_FILE}'"
                    fi
                fi
            done

            echo " "
            echo -e "${Color_Off} -> Packages to be ${Yellow}installed:${Cyan}${PACKAGE_LIST}${Color_Off}"
            echo " "

            sudo sh -c "echo ' -----------------------------------------------' >> '${LOG_FILE}'"
            sudo sh -c "echo ' System Packages - Installation' >> '${LOG_FILE}'"
            if [ -n "${PACKAGE_LIST}" ]; then
                echo " "
                SCRIPT_ACTION="installing packages"
                echo -e " Script Status: ${Purple}${SCRIPT_ACTION}${Color_Off}"
                PACKAGE_LIST_WSPACE="$(echo -e "${PACKAGE_LIST}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
                IFS=' ' read -ra PACKAGE_LIST_INSTALL <<<"${PACKAGE_LIST_WSPACE}"

                for PACKAGE_INSTALL in "${PACKAGE_LIST_INSTALL[@]}"; do
                    echo -e "${Color_Off} + ${Cyan}${PACKAGE_INSTALL}${Color_Off}: ${IYellow}installing${Color_Off}"
                    sudo sh -c "echo ' ' >> '${LOG_FILE}'"
                    sudo sh -c "echo ' + ${PACKAGE_INSTALL}: installing' >> '${LOG_FILE}'"
                    sudo sh -c "echo ' -----------------------------------------------' >> '${LOG_FILE}'"
                    sudo dnf install "${PACKAGE_INSTALL}" -y --quiet | sudo tee -a "${LOG_FILE}"
                    sudo sh -c "echo ' -----------------------------------------------' >> '${LOG_FILE}'"
                done

            fi

            sudo sh -c "echo '================================================' >> '${LOG_FILE}'"

            # NTP for RHEL with chrony
            # keep track of deployment status
            STATUS_STEP="chrony"
            STATUS_FILE="${STATUS_FILE_PREFIX}.${STATUS_STEP}.txt"

            if [[ ! -f "${STATUS_FILE}" ]]; then
                echo "allow 192.168.100.0/24" | sudo tee -a /etc/chrony.conf
                echo "log measurements statistics tracking" | sudo tee -a /etc/chrony.conf
                sudo systemctl enable --now chronyd
                sudo timedatectl set-ntp true
                sudo chronyc sources
                sudo touch "${STATUS_FILE}"
            fi

            # keep track of deployment status
            STATUS_STEP="selinux"
            STATUS_FILE="${STATUS_FILE_PREFIX}.${STATUS_STEP}.txt"
            # SElinux
            if [[ ! -f "${STATUS_FILE}" ]]; then
                sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
                sudo touch "${STATUS_FILE}"
            fi

            # keep track of deployment status
            STATUS_STEP="openssl"
            STATUS_FILE="${STATUS_FILE_PREFIX}.${STATUS_STEP}.txt"
            # OpenSSL
            if [[ ! -f "${STATUS_FILE}" ]]; then
                sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
                sudo touch "${STATUS_FILE}"
            fi

        else

            SCRIPT_ACTION="not updating, no active RHEL subscription"
            echo -e " Script Status: ${Purple}${SCRIPT_ACTION}${Color_Off}"
        fi
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
