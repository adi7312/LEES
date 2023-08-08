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
    ssh_dirs=`find / -name .ssh -exec ls -la {} 2>/dev/null \;` 
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

    # Enumerating DNS
    dns=`cat /etc/resolv.conf 2>/dev/null`
    if [[ $dns ]]; then
        echo -e "[*] DNS info: \n$dns"
    else
        echo -e "[-] Can't get any DNS info"
    fi

    # Route information
    route=`ip r 2>/dev/null | grep default`
    if [[ $route ]]; then
        echo -e "[*] Route info: \n$route"
    else
        echo -e "[-] Can't get any route info"
    fi
}

function env_enum(){
    echo -e '\e[0;32m-------------------Performing environment enumeration-------------------\e[m'
    # checking env variables
    env=`env 2>/dev/null`
    if [[ $env ]]; then
        echo -e "[*] Env variables: \n$env"
    else
        echo -e "[-] Can't get any env variables"
    fi

    # check current PATH
    path=`echo $PATH 2>/dev/null`
    if [[ $path ]]; then
        echo -e "[*] Current PATH: \n$path"
    else
        echo -e "[-] Can't get current PATH"
    fi

    # check available shells
    shells=`cat /etc/shells 2>/dev/null | tail -n +1`
    if [[ $shells ]]; then
        echo -e "[*] Available shells: \n$shells"
    else
        echo -e "[-] Can't get available shells"
    fi


}

function files_enum(){
    echo -e '\e[0;32m-------------------Performing files enumeration-------------------\e[m'
    # checking suid binaries from GTFO, via HackTheBox
    suid_binaries=`find / -perm -4000 -type f 2>/dev/null`
    if [[ $suid_binaries ]]; then
        echo -e "\e[0;31m[+] SUID binaries: \n$suid_binaries\e[m"
    else
        echo -e "[-] Can't get any SUID binaries"
    fi

    # looking for .config files
    config_files=`find / ! -path /proc -iname "*config*" 2>/dev/null`
    if [[ $config_files ]]; then
        echo -e "[*] config files: \n"
        echo -e "\e[0;34m$config_files\e[m"
    else
        echo -e "[-] Can't get any .config files"
    fi

    # looking for .bak files
    bak_files=`find / ! -path /proc -iname "*.bak*" 2>/dev/null`
    if [[ $bak_files ]]; then
        echo -e "[*] Found some .bak files: \n"
        echo -e "\e[0;34m$bak_files\e[m"
    else
        echo -e "[-] Can't get any .bak files"
    fi

    # installed compilers
    compilers=`dpkg --list 2>/dev/null| grep compiler`
    if [[ $compilers ]]; then
        echo -e "[*] Installed compilers: \n"
        echo -e "\e[0;34m$compilers\e[m"
    else
        echo -e "[-] Can't get any installed compilers"
    fi

    # looking for sgid files
    sgid_files=`find / ! -path /proc -perm -2000 -type f 2>/dev/null`
    if [[ $sgid_files ]]; then
        echo -e "\e[0;31m[+] Found some sgid files: \n\e[m"
        echo -e "\e[0;34m$sgid_files\e[m"
    else
        echo -e "[-] Can't get any sgid files"
    fi

    # checking files with capabilities
    capabilities=`getcap -r / 2>/dev/null`
    if [[ $capabilities ]]; then
        echo -e "[*] Files with capabilities: \n"
        echo -e "\e[0;34m$capabilities\e[m"
    else
        echo -e "[-] Can't get any files with capabilities"
    fi

    # lookig for private keys
    echo -e "\e[1;33mWarning: this operation could be slow\e[m"
    read -p 'Do you want to look for private keys?? [n/y]: ' option
    if [[ $option == 'y' ]]; then
        priv_keys=`grep -rl PRIVATE KEY---- /home 2>/dev/null`
        if [[ $priv_keys ]]; then
            echo -e "\e[0;31m[+] Found some private keys: \n\e[m"
            echo -e "\e[0;34m$priv_keys\e[m"
        else
            echo -e "[-] Can't get any private keys"
        fi
    fi

    # lookig for git credentials
    git=`find / -type f -name ".git-credentials" 2>/dev/null`
    if [[ $git ]]; then
        echo -e "\e[0;31m[+] Found some git credentials: \n\e[m"
        echo -e "\e[0;34m$git\e[m"
    else
        echo -e "[-] Can't get any git credentials"
    fi

    # listing nfs shares
    nfs=`showmount -e 2>/dev/null`
    if [[ $nfs ]]; then
        echo -e "[*] NFS shares: \n"
        echo -e "\e[0;34m$nfs\e[m"
    else
        echo -e "[-] Can't get any NFS shares"
    fi

    # listing smb shares
    smb=`smbclient -L \\\\localhost -N 2>/dev/null`
    if [[ $smb ]]; then
        echo -e "[*] SMB shares: \n"
        echo -e "\e[0;34m$smb\e[m"
    else
        echo -e "[-] Can't get any SMB shares"
    fi

    # checking htpasswd
    htpasswd=`find / -name .htpasswd -print -exec cat {} \; 2>/dev/null`
    if [[ $htpasswd ]]; then
        echo -e "\e[0;31m[+] Found some htpasswd files (possible credentials leak): \n\e[m"
        echo -e "\e[0;34m$htpasswd\e[m"
    else
        echo -e "[-] Can't get any htpasswd files"
    fi
}

function cron_enum(){
    echo -e '\e[0;32m-------------------Performing cron jobs enumeration-------------------\e[m'
    # checking cron jobs
    cron=`ls -la /etc/cron* 2>/dev/null; cat /etc/crontab 2>/dev/null; crontab -l 2>/dev/null`
    if [[ $cron ]]; then
        echo -e "[*] Cron jobs: \n$cron"
    else
        echo -e "[-] Can't get any cron jobs"
    fi

    # checking if we can modify any cron job
    cron_files=`find /etc/cron* -perm -o+w 2>/dev/null`
    if [[ $cron_files ]]; then
        echo -e "\e[0;31m[+] You can modify the following cron jobs: \n\e[m"
        echo -e "\e[0;34m$cron_files\e[m"
    else
        echo -e "[-] Can't modify any cron job"
    fi
    
    # checking crontabs of other uses
    cronusers=`cut -d ":" -f 1 /etc/passwd | xargs -n1 crontab -l -u 2>/dev/null`
    if [[ $cronusers ]]; then
        echo -e "\e[0;31m[+] Cron jobs of other users: \n\e[m"
        echo -e "\e[0;34m$cronusers\e[m"
    else
        echo -e "[-] Can't get any cron jobs of other users"
    fi

}

function service_enum(){
    echo -e '\e[0;32m-------------------Performing service and software enumeration-------------------\e[m'
    # checking running processes
    processes=`ps aux 2>/dev/null`
    if [[ $processes ]]; then
        echo -e "\e[0;31m[+] Running processes: \n\e[m"
        echo -e "\e[0;34m$processes\e[m"
    else
        echo -e "[-] Can't get any running processes"
    fi

    # check content of init.d 
    initd=`ls -la /etc/init.d/ 2>/dev/null`
    if [[ $initd ]]; then
        echo -e "\e[0;31m[+] Content of init.d: \n\e[m"
        echo -e "\e[0;34m$initd\e[m"
    else
        echo -e "[-] Can't get any content of init.d"
    fi

    # checking if mysql is installed
    mysql=`mysql --version 2>/dev/null`
    if [[ $mysql ]]; then
        echo -e "[*] MySQL version: $mysql\n"
    else
        echo -e "[-] Can't get MySQL version"
    fi

    # checking if postgres is installed
    postgres=`psql --version 2>/dev/null`
    if [[ $postgres ]]; then
        echo -e "[*] Postgres version: $postgres\n"
        
    else
        echo -e "[-] Can't get Postgres version"
    fi

    # checking if apache is installed
    apache=`apache2 -v 2>/dev/null`
    if [[ $apache ]]; then
        echo -e "[*] Apache version: $apache\n"
    else
        echo -e "[-] Can't get Apache version"
    fi

}

function docker_enum(){
    echo -e '\e[0;32m-------------------Performing docker enumeration-------------------\e[m'

    # checking if we are inside container
    container=`cat /proc/self/cgroup 2>/dev/null | grep -i docker; find / -name "*dockerenv*" 2>/dev/null`
    if [[ $container ]]; then
        echo -e "\e[0;31m[+] You are probably inside docker container: \n\e[m"
        echo -e "\e[0;34m$container\e[m"
    else
        echo -e "[-] You are not inside docker container"
    fi

    # check docker version
    docker_ver=`docker --version 2>/dev/null`
    if [[ $docker_ver ]]; then
        echo -e "[*] Docker version: $docker_ver\n"
    else
        echo -e "[-] Can't get Docker version"
    fi

    # check docker files
    docker_files=`find / -name "Dockerfile" -exec ls -l {} 2>/dev/null \;`
    if [[ $docker_files ]]; then
        echo -e "[*] Fond some Docker files: \n"
        echo -e "\e[0;34m$docker_files\e[m"
    else
        echo -e "[-] Can't get Docker files"
    fi

    # check docker images
    docker_images=`docker images 2>/dev/null`
    if [[ $docker_images ]]; then
        echo -e "[*] Docker images: \n"
        echo -e "\e[0;34m$docker_images\e[m"
    else
        echo -e "[-] Can't get Docker images"
    fi

}

function lxc_lxd_enum(){
    echo -e '\e[0;32m-------------------Performing LXC/LXD enumeration-------------------\e[m'
    # check if we are inside lxc/lxd container
    lxc=`cat /proc/self/cgroup 2>/dev/null | grep -i lxc || grep -qa container=lxc /proc/1/environ 2>/dev/null`
    if [[ $lxc ]]; then
        echo -e "\e[0;31m[+] You are probably inside lxc/lxd container: \n\e[m"
        echo -e "\e[0;34m$lxc\e[m"
    else
        echo -e "[-] You are not inside lxc/lxd container"
    fi


}



system_enum
user_enum
net_enum
env_enum
files_enum
cron_enum
service_enum
docker_enum
lxc_lxd_enum