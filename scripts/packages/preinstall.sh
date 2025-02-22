#!/bin/sh
set -e

# Copyright (C) Nginx, Inc. 2022.
#
# Description:
# NGINX Agent install script for downloading the NGINX Agent package from the appropriate repository
#
################################
###### Changeable variables
################################

LOG_LEVEL=""
INSTANCE_GROUP=""

################################
###### Default variables
################################
export AGENT_GROUP="${AGENT_GROUP:-$(id -ng)}"

# Determine OS platform
# shellcheck source=/dev/null
. /etc/os-release

if [ "$ID" = "freebsd" ]; then
    AGENT_CONFIG_FILE=${AGENT_CONFIG_FILE:-"/usr/local/etc/nginx-agent/nginx-agent.conf"}
    AGENT_DYNAMIC_CONFIG_DIR="/usr/local/etc/nginx-agent"
    mkdir -p /var/log/nginx-agent/
else
    AGENT_CONFIG_FILE=${AGENT_CONFIG_FILE:-"/etc/nginx-agent/nginx-agent.conf"}
    AGENT_DYNAMIC_CONFIG_DIR="/etc/nginx-agent"
fi

AGENT_DYNAMIC_CONFIG_FILE="${AGENT_DYNAMIC_CONFIG_DIR}/agent-dynamic.conf"
AGENT_DYNAMIC_CONFIG_COMMENT="#
# dynamic-agent.conf
#
# Dynamic configuration file for NGINX Agent.
#
# The purpose of this file is to track agent configuration
# values that can be dynamically changed via the API and the agent install script.
# You may edit this file, but API calls that modify the tags on this system will
# overwrite the tag values in this file.
#
# The agent configuration values that API calls can modify are as follows:
#    - tags
#
# The agent configuration value(s) that the agent install script can modify are as follows:
#    - instance_group

"

#
# Functions
#

err_exit() {
    printf "\n%b" "$1"
    printf " exiting.\n"
    exit 1
}

title() {
    printf "\n --- NGINX Agent Package Installer --- \n\n"
    printf " --- Will install the NGINX Agent in 5 seconds ---\n"
    sleep 5
}

ensure_sudo() {
    if [ "$(id -u)" = "0" ]; then
        echo "Sudo permissions detected"
    else
        err_exit "No sudo permission detected, please run as sudo"
    fi
}

load_config_values() {
    # If the file doesn't exist attempt to create it
    if [ ! -f "$AGENT_DYNAMIC_CONFIG_FILE" ]; then
        printf "Could not find %s ... Creating file\n" ${AGENT_DYNAMIC_CONFIG_FILE}
        mkdir -p ${AGENT_DYNAMIC_CONFIG_DIR}
        printf "%s" "${AGENT_DYNAMIC_CONFIG_COMMENT}" | tee ${AGENT_DYNAMIC_CONFIG_FILE} > /dev/null
        printf "Successfully created %s\n" "${AGENT_DYNAMIC_CONFIG_FILE}"
    fi

    # Check if there are existing values
    _instance_group="$(grep "^instance_group:" "${AGENT_DYNAMIC_CONFIG_FILE}" | head -n 1 | cut -d : -f 2 | sed "s/^[[:space:]]//")"

    if [ "$_instance_group" ] && [ ! "${INSTANCE_GROUP}" ]; then
        INSTANCE_GROUP=$_instance_group
    fi
}

update_config_file() {
    if [ ! -f "$AGENT_CONFIG_FILE" ]; then
        printf "Agent config file %s does not exist. Could not be updated\n" "$AGENT_CONFIG_FILE"
        exit 0
    fi

    printf "Updating %s ...\n" "${AGENT_CONFIG_FILE}"

    # Replace Host
    sed_cmd="sed -i.bak "
    ${sed_cmd} "s/host:.*$/host: ${PACKAGE_HOST}/" "${AGENT_CONFIG_FILE}"

    # Check the log-level and set accordingly
    if [ "${LOG_LEVEL}" ]; then
        if [ "$(grep -cP '^(?=[\s]*+[^#])[^#]*(level:)' "${AGENT_CONFIG_FILE}")" -ge 1 ]; then
            printf "Setting existing log level: %s\n" "${LOG_LEVEL}"
            ${sed_cmd} "/^[[:space:]]*#/!s/\(level:.*\)/level: ${LOG_LEVEL}/g" "${AGENT_CONFIG_FILE}"
        else
            printf "Setting log level: %s\n" "${LOG_LEVEL}"
            _log_level_replacement="s/^log:/log:\\
  level: ${LOG_LEVEL}/"
            ${sed_cmd} "${_log_level_replacement}" "${AGENT_CONFIG_FILE}"
            printf "Successfully updated %s\n" "${AGENT_CONFIG_FILE}"
        fi
    fi

    printf "Successfully updated %s\n" "${AGENT_CONFIG_FILE}"

    # Check the instance group and set accordingly
    if [ "${INSTANCE_GROUP}" ]; then
        printf "Updating %s ...\n" "${AGENT_DYNAMIC_CONFIG_FILE}"

        if [ "$(grep -cP '^(?=[\s]*+[^#])[^#]*(instance_group)' "${AGENT_DYNAMIC_CONFIG_FILE}")" -ge 1 ]; then
            printf "Setting existing instance_group: %s\n" "${INSTANCE_GROUP}"
            ${sed_cmd} "/^[[:space:]]*#/!s/\(instance_group:.*\)/instance_group: ${INSTANCE_GROUP}/g" "${AGENT_DYNAMIC_CONFIG_FILE}"
        else
            printf "Setting instance_group: %s\n" "${INSTANCE_GROUP}"
            printf "instance_group: %s\n" "${INSTANCE_GROUP}" >> "${AGENT_DYNAMIC_CONFIG_FILE}"
        fi

        printf "Successfully updated %s\n" "${AGENT_DYNAMIC_CONFIG_FILE}"
    fi
}

#
# Main body of the script
#
{
    title
    ensure_sudo
    load_config_values
    update_config_file
}
