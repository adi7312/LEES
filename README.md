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