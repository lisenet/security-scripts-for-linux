#!/bin/bash
#--------------------------------------------
# Name:     SECURITY TOOLS INSTALLER
# Author:   Tomas Nevar (tomas@lisenet.com)
# Version:  v1.0
# Licence:  copyleft free software
#--------------------------------------------
#
# Developed and tested on Ubuntu 14.04 x64
# May work on other Ubuntu/Debian, but YMMV
#
# Installation directory
DIR="/home/"$USER"/bin";

#############################################
# CHECK IF RUNNING AS ROOT                  #
#############################################
if [ "$EUID" -eq "0" ]; then
  echo "Please be nice and don't run as root.";
  exit 1;
fi

#############################################
# CHECK IF USER BELONGS TO SUDO GROUP       #
#############################################
if ! grep -qe sudo.*$USER /etc/group ; then
  echo "User "$USER" does not belong to sudo group. Exiting.";
  exit 1;
fi

#############################################
# CHECK FOR INSTALLATION DIRECTORY          #
#############################################
if [ -d "$DIR" ]; then
  echo ""$DIR" already exists. Aborting."
  exit 1;
else
  mkdir -pv "$DIR";
  cd "$DIR";
fi
#
# PREREQUISITES
#
sudo apt-get update -q;
sudo apt-get install -y perl perl-modules libnet-ssleay-perl libwhisker2-perl \
python2.7 python2.7-dev python-requests python-ctypes python-beautifulsoup \
python-pip python-gitdb python-yaml libssl-dev libxml2-dev libxslt1-dev wget \
libyaml-dev libsqlite3-dev libpcre3 libpcre3-dev libidn11-dev openssl git \
build-essential libffi-dev;

# Required by Wapiti
sudo pip install BeautifulSoup4;
# Required by W3AF
sudo pip install clamd==1.0.1 PyGithub==1.21.0 GitPython==0.3.2.RC1 \
pybloomfiltermmap==0.3.11 esmre==0.3.1 phply==0.9.1 stopit==1.1.0 nltk==3.0.1 \
chardet==2.1.1 tblib==0.2.0 pdfminer==20140328 futures==2.1.5 pyOpenSSL==0.13.1 \
ndg-httpsclient==0.3.3 pyasn1==0.1.3 lxml==2.3.2 scapy-real==2.2.0-dev \
guess-language==0.2 cluster==1.1.1b3 msgpack-python==0.4.4 python-ntlm==1.0.1 \
halberd==0.2.4 darts.util.lru==0.5 Jinja2==2.7.3;

#
# NMAP
#
sudo apt-get install nmap -y;
#
# LYNIS from GitHub
#
git clone https://github.com/CISOfy/Lynis.git;
sudo chown -R root:root ./Lynis/include;
sudo chmod 600 ./Lynis/include;
#
# NIKTO from GitHub
#
git clone https://github.com/sullo/nikto.git;
chown -R "$USER":"$USER" ./nikto;
chmod u+x ./nikto/program/nikto.pl;
#
# WAPITI from GitHub
#
git clone https://github.com/IFGHou/wapiti.git;
chown -R "$USER":"$USER" ./wapiti;
chmod u+x ./wapiti/bin/wapiti;
#
# W3AF from GitHub
#
git clone https://github.com/andresriancho/w3af.git;
chown -R "$USER":"$USER" ./w3af;
chmod u+x ./w3af/w3af_console;
#
# ARACHNI
#
wget http://downloads.arachni-scanner.com/arachni-1.0.6-0.5.6-linux-x86_64.tar.gz;
tar xfz arachni-1.0.6-0.5.6-linux-x86_64.tar.gz;
mv arachni-1.0.6-0.5.6 arachni;
chown -R "$USER":"$USER" ./arachni;
#
# SKIPFISH
#
wget http://skipfish.googlecode.com/files/skipfish-2.10b.tgz;
tar xfz ./skipfish-2.10b.tgz;
mv ./skipfish-2.10b ./skipfish;
chown -R "$USER":"$USER" ./skipfish;
cd ./skipfish && make;

# Remote all tarballs as these are no longer needed
rm -v "$DIR"/*gz;

exit 0
