# security-scripts-for-linux
Various scripts to check for web applications, Linux OS etc vulnerabilities. Damn Vulnerable Web App (DVWA) is a good starting point.

## DISCLAIMER

Consider using Kali Linux for pentesting and vulnerability scanning. 

## sec-tools-installer
Bash script that installs the following tools:
* Nmap
* Lynis
* Nikto
* Wapiti
* W3AF
* Arachni
* Skipfish

Download links tend to break, therefore consider yourself warned.

The script was developed and tested on Ubuntu 14.04 x64. It may work on other Ubuntu/Debian distributions, but YMMV.

## sec-tools-scanner
Bash script that scans a web application for vulnerabilities.

The `sec-tools-scanner` uses the security tools that were installed by using the `sec-tools-installer` script.
