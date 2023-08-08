# **Linux Enviornment Enumeration Script**

Purpose: finding possible privilege escalation vectors

For now, script perfrom these tasks:

* System enumeration:
  * Hostname
  * Kernel version
  * OS release
* User enumeration:
  * Groups
  * Content of /etc/passwd and /etc/shadow
  * Checking existing users
  * Sudo versions, sudo commands
  * Writable files
  * .ssh directories
* Network enumeration:
  * ARP table
  * Network interfaces
  * Routing
  * DNS information
  * Listening TCP/UDP ports
* Evironment enumeration:
  * Checkinge env variables
  * Checking /etc/shells
* Files enum:
  * SUID binaries
  * SGID binaries
  * Capabilities
  * Config files
  * .bak files
  * Available compilers
  * Private keys
  * Git credentials
  * NFS Shares
* Crontab enum:
  * Checking crons/jobs of current and other users
* Service enum:
  * Running processess
  * Content of init.d
  * Checking installed serivces: mysql, postgresql, apache2 (more services will be added in the future)
* Docker enum:
  * Checking if we are inside container
  * Docker version, images, files (to be expanded)
* LXC/LXD enum:
  * Checking if we are LXC/LXD container
  

Running script:
    
    git clone https://github.com/adi7312/LEES.git
    cd LEES
    chmod +x lees.sh
    ./lees.sh