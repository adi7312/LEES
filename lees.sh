#!/bin/bash

echo -e '[*] STARTING LEES (Linux Environment Enumeration Script)...'

function system_enum() { 
    echo -e '\e[0;32m-------------------Performing system enumeration-----------------\e[m'

    hostname=`hostname`
    echo -e "[-] Hostname: \e[0;34m$hostname \e[m"

    kernel=`cat /proc/version`
    echo -e "[-] Kernel version: \e[0;34m$kernel\e[m"

    os_release=`cat /etc/os-release | head -n 1 | sed 's/PRETTY_NAME=//g'`
    echo -e "[-] OS release: \e[0;34m$os_release\e[m"

}

function user_enum(){

    echo -e '\e[0;32m-------------------Performing user enumeration-------------------\e[m'

    # Checking interesting groups
    interesting_groups=("root" "sudo" "admin" "wheel" "video" "disk" "shadow" "adm" "docker" "lxc" "lxd")
    user_id=`id`
    possible_vectores=()
    echo -e "[-] User id: \e[0;34m$user_id\e[m"
    for g in ${interesting_groups[@]}; do
        if [[ "$user_id" == *"$g"* ]]
        then
            echo -e "\e[0;31m[+] Found interesting group (potential privilege escalation vector): $g\e[m"
        else
            continue
        fi
    done

    # Checking logged in users
    logged=`w | tail -n +3`
    if [[ "$logged" ]]; then
        echo -e "[-] Logged users:\n"
        w
    else
        echo -e "[-] Couldn't find any logged users"
    fi

    # Checking if /etc/passwd contains password hashes

    passwd=`cat /etc/passwd | grep -v '^[^:]*:[x]' 2>/dev/null`
    if [[ "$passwd" ]]; then
        echo -e "\e[0;31m[+] Hashes found in /etc/passwd: \e[m"
        echo -e "\e[0;34m$passwd\e[m"
    else
        echo -e "[-] /etc/passwd doesn't contain hashes"
    fi

    # Checking if /etc/shadow can be read
    etc_shadow=`cat /etc/shadow 2>/dev/null`
    if [[ $etc_shadow ]]; then
        echo -e "\e[0;31m[+] Shadow file can be read! \e[m"
        echo -e "\e[0;34m$etc_shadow\e[m"
    else
        echo -e "[-] Can't get access to shadow file"
    fi    

}




system_enum
user_enum