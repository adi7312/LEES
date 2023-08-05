#!/bin/bash

echo -e '[*] Starting LEES (Linux Environment Enumeration Script)...'

function system_enum() { 
    echo -e '\e[0;32m[*] Performing system enumeration...\e[m'

    hostname=`hostname`
    echo -e "[-] Hostname: \e[0;34m$hostname \e[m"

    kernel=`cat /proc/version`
    echo -e "[-] Kernel version: \e[0;34m$kernel\e[m"

    os_release=`cat /etc/os-release | head -n 1 | sed 's/PRETTY_NAME=//g'`
    echo -e "[-] OS release: \e[0;34m$os_release\e[m"

}

function user_enum(){
    echo -e '\e[0;32m[*] Performing user enumeration...\e[m'
    interesting_groups=("root" "sudo" "admin" "wheel" "video" "disk" "shadow" "adm" "docker" "lxc" "lxd")
    user_id=`id`
    echo -e "[-] User id: \e[0;34m$user_id\e[m"
    for g in ${interesting_groups[@]}; do
        if [[ "$user_id" == *"$g"* ]]
        then
            echo -e "\e[0;31m[+] Found interesting group (potential privilege escalation vector): $g\e[m"
        else
            continue
        fi
    done
    echo -e test
}


system_enum
user_enum