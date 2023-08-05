#!/bin/bash

echo -e '\e[1;33m[*] STARTING LEES (Linux Environment Enumeration Script)...\e[m'

function system_enum() { 
    echo -e '\e[0;32m-------------------Performing system enumeration-----------------\e[m'

    hostname=`hostname`
    echo -e "[*] Hostname: \e[0;34m$hostname \e[m"

    kernel=`cat /proc/version`
    echo -e "[*] Kernel version: \e[0;34m$kernel\e[m"

    os_release=`cat /etc/os-release | head -n 1 | sed 's/PRETTY_NAME=//g'`
    echo -e "[*] OS release: \e[0;34m$os_release\e[m"

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
        echo -e "[*] Logged users:\n"
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


    # All accounts with UID 0
    uid_0=`awk -F: '($3 == "0") {print}' /etc/passwd`
    if [[ $uid_0 ]]; then
        echo -e "\e[0;31m[+] Accounts with UID 0: \e[m"
        echo -e "\e[0;34m$uid_0\e[m"
    else
        echo -e "[-] No accounts with UID 0"
    fi

    # Show sudoers info
    sudoers=`cat /etc/sudoers | grep -v '^#' | grep -v '^$' 2>/dev/null`
    if [[ $sudoers ]]; then
        echo -e "[*] Sudoers file: "
        echo -e "\e[0;34m$sudoers\e[m"
    else
        echo -e "[-] Can't get access to sudoers file"
    fi

    # Show sudo version
    sudo_version=`sudo -V 2>/dev/null | head -n 1 | sed 's/Sudo version //g'`
    if [[ $sudo_version ]]; then
        echo -e "[*] Sudo version: \e[0;34m$sudo_version\e[m"
        sudo_version=`echo $sudo_version | sed 's/\./ /g'`
        sudo_version=($sudo_version)
        if [[ ${sudo_version[0]} -le 1 && ${sudo_version[1]} -le 8 && ${sudo_version[2]} -lt 28 ]]; then
            echo -e "\e[0;31m[+] Sudo version is below 1.8.28, potential privilege escalation vector (CVE-2019-14287)\e[m"
        else
            echo -e "[-] Sudo version is above 1.8.28, not vulnerable to CVE-2019-14287"
        fi
    fi
        

    # Show sudo -l
    sudo_l=`sudo -l 2>/dev/null | tail -n +4`
    if [[ $sudo_l ]]; then
        echo -e "[*] Sudo -l: \e[0;34m\n$sudo_l\e[m"
    else
        echo -e "[-] Can't get access to sudo -l"
    fi

    # Checking if /root can be  read
    root=`ls -la /root 2>/dev/null`
    if [[ $root ]]; then
        echo -e "\e[0;31m[+] /root can be read! \e[m"
    else
        echo -e "[-] Can't get access to /root"
    fi

    # checking writable files, not own by user
    echo -e "\e[1;33mWarning: this operation is really slow\e[m"
    read -p 'Do you want to check writable files? [n/y]: ' option
    if [[ $option == 'y' ]]; then
         writable_files=`find / -writable ! -user \`whoami\` -type f ! -path "/proc/*" ! -path "/sys/*" -! -path "/dev/*" -exec ls -al {} \; 2>/dev/null`
        if [[ $writable_files ]]; then
            echo -e "\e[0;31m[+] Writable files not owned by user: \e[m"
            echo -e "\e[0;34m$writable_files\e[m"
        else
            echo -e "[-] No writable files not owned by user"
        fi
    fi
    
    # finding .ssh directories
    echo -e "[*] Looking for ssh directories"
    ssh_dirs=`timeout 1 find / -name .ssh -exec ls -la {} 2>/dev/null \;` 
    if [[ $ssh_dirs ]]; then
        echo -e "\e[0;31m[+] .ssh directories found: \e[m"
        echo -e "\e[0;34m$ssh_dirs\e[m"
    else
        echo -e "[-] No .ssh directories found"
    fi

    # check if the root is allowed to connect via ssh
    root_ssh=`grep "PermitRootLogin " /etc/ssh/sshd_config 2>/dev/null | grep -v "#" | awk '{print  $2}'`
    if [[ $root_ssh == "yes" ]]; then
        echo -e "\e[0;31m[+] Root is allowed to connect via ssh \e[m"
    else
        echo -e "[-] Root is not allowed to connect via ssh"
    fi
   
}

function net_enum(){
    echo -e '\e[0;32m-------------------Performing network enumeration-------------------\e[m'
    # checking arp tables
    arp_history=`arp -a 2>/dev/null`
    if [[ $arp_history ]]; then
        echo -e "[*] ARP info: \n$arp_history"
    fi

    arpinfo=`ip n 2>/dev/null`
    if [ ! "$arp_history" ] && [ "$arpinfo" ]; then
        echo -e "[*] ARP history: \n$arpinfo" 
    else
        echo -e "[-] Can't get any ARP info"
    fi

    # checking network interfaces
    interfaces=`ip a 2>/dev/null`
    if [[ $interfaces ]]; then
        echo -e "[*] Network interfaces: "
        echo -e "$interfaces"
    else
        echo -e "[-] Can't get any network interfaces"
    fi

    # Checking listening UDP ports

    udp_ports=`netstat -ulpn 2>/dev/null | grep udp`
    if [[ $udp_ports ]]; then
        echo -e "[*] Listening UDP ports:\n$udp_ports"
    else
        echo -e "[-] No listening UDP ports"
    fi

    # Checking listening TCP ports
    tcp_ports=`netstat -lpn 2>/dev/null | grep tcp`
    if [[ $tcp_ports ]]; then
        echo -e "[*] Listening TCP ports:\n$tcp_ports"
    else
        echo -e "[-] No listening TCP ports"
    fi
}





system_enum
user_enum
net_enum