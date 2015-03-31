#!/bin/bash
#--------------------------------------------
# Name:     SECURITY SCANNER
# Author:   Tomas Nevar (tomas@lisenet.com)
# Version:  v1.0
# Licence:  copyleft free software
#--------------------------------------------
#
# Target DNS (not URL!) to scan
TARGET="127.0.0.1";
HTTP_USER="Admin";
HTTP_PASS="password";
USER_AGENT="sec-tools-scanner.sh";

# Maximum testing time per host in sec/min
MAX_SCAN_SECONDS="1200";
MAX_SCAN_MINUTES="20";
# Timeout for requests in seconds
TIMEOUT="30"; 

#
# You do not have to change anything else
#
URL="http://";
PORT="80";
OUT1="/tmp/scan-nmap.txt";
OUT2="/tmp/scan-nikto.txt";
OUT3="/tmp/scan-wapiti.txt";
OUT4="/tmp/scan-arachni.txt";
OUT5="/tmp/scan-w3af.txt";
TMP1="/tmp/tmp1";
TMP2="/tmp/tmp2";
TMP3="/tmp/tmp3";
TMP4="/tmp/tmp4";
TMP5="/tmp/tmp5";
OUTRESULT="/tmp/"$TARGET".txt";
W3AF_SCRIPT="/tmp/w3af-script.w3af";
# Paths to Nikto, Wapiti, Arachni and W3AF installation
PATH_NIKTO="/home/"$USER"/bin/nikto/program";
PATH_WAPITI="/home/"$USER"/bin/wapiti/bin";
PATH_ARACHNI="/home/"$USER"/bin/arachni/bin";
PATH_W3AF="/home/"$USER"/bin/w3af";

# Append the PATH variable to be able to find 
# manually installed packages
PATH="$PATH:"$PATH_NIKTO":"$PATH_WAPITI":"$PATH_ARACHNI":"$PATH_W3AF"";

#############################################
# CHECK IF RUNNING AS ROOT                  #
#############################################
if [ "$EUID" -eq "0" ]; then
  echo "Please be nice and don't run as root.";
  exit 1;
fi

#############################################
# CHECK IF SCANNERS ARE INSTALLED           # 
#############################################
echo "Assuming that the sec tools were installed by using sec-tools-installer.sh";
echo "Checking for tools and scanners.";
type pip >/dev/null 2>&1 || { echo "I require python-pip but it's not installed. Aborting."; exit 1; };
echo "pip: FOUND";
type nmap >/dev/null 2>&1 || { echo "I require Nmap but it's not installed. Aborting."; exit 1; };
echo "Nmap: FOUND";
type nikto.pl >/dev/null 2>&1 || { echo "I require Nikto but it's not installed. Aborting."; exit 1; };
echo "Nikto: FOUND";
type wapiti >/dev/null 2>&1 || { echo "I require Wapiti but it's not installed. Aborting."; exit 1; };
echo "Wapiti: FOUND";
type arachni >/dev/null 2>&1 || { echo "I require Arachni but it's not installed. Aborting."; exit 1; };
echo "Arachni: FOUND";
type w3af_console >/dev/null 2>&1 || { echo "I require w3af_console but it's not installed. Aborting."; exit 1; };
echo "w3af_console: FOUND";

#############################################
# CHECK FOR LOW RAM INSTALLATION            # 
#############################################
RAM=$(grep MemTotal /proc/meminfo|awk '{print $2}');

if [[ "$RAM" -lt "1024000" ]]; then
  echo -e "\nLess than one 1GB of RAM was found on the system: "$RAM"kB.
You may run out of memory. Consider yourself warned.";
fi

#############################################
# ASK FOR PIP UPGRADE                       # 
#############################################
echo "";
while true; do
  read -p "Do you want to upgrade pip (y/n)? Saying yes is a good idea: " yn
  case $yn in
    [Yy]* ) 
      echo "Upgrading pip.";
      sudo pip install --upgrade pip;
      break;;
    [Nn]* )
      break;;
    * ) echo "Please answer 'y' or 'n'.";;
  esac
done

# Erase any previous scans results
>"$OUT1";>"$OUT2";>"$OUT3";>"$OUT4";>"$OUT5";

###########################################
# RUN NMAP PORT SCAN                      #
###########################################
while true; do
  read -p "Press 'y' to start an Nmap port scan, or 'n' to exit: " yn
  case $yn in
    [Yy]* )
      break;;
    [Nn]* )
      exit 0;;
    * ) echo "Please answer 'y' or 'n'.";;
  esac
done

echo -e "\nStarted Nmap port scan against: "$TARGET"";

# Start with Nmap scan and get port states (open/closed/filtered) for 80 and 443
/usr/bin/nmap -Pn -p T:21,22,80,443,1433,3306,3389 -sV -T4 -oN "$OUT1" "$TARGET";
STATE_HTTP=$(grep '80/tcp' "$OUT1"|awk '{ print $2 }');
STATE_HTTPS=$(grep '443/tcp' "$OUT1"|awk '{ print $2 }');

# Check for ports 80 and 443, if 443 is open, run a scan against it.
# If 443 is closed but 80 is open, run a scan against it.
# Exit if both ports 80 and 443 are closed.
if [[ "$STATE_HTTPS" == *open* ]]
then
  echo "443 port is" "$STATE_HTTPS";
  URL="https://";
  PORT="443";
elif [[ "$STATE_HTTP" == *open* ]]; then
  echo "80 port is" "$STATE_HTTP";
  URL="http://";
  PORT="80";
else
  echo "According to Nmap, ports 80 and 443 are closed. Script exits here.";
  exit 0;
fi

###########################################
# RUN NIKTO SCAN                          #
###########################################
echo "";
while true; do
  read -p "Do you want to run a Nikto scan (y/n)? " yn
  case $yn in
    [Yy]* )
      START_T="$SECONDS";

      nikto.pl -h "$TARGET" -p "$PORT" -id "$HTTP_USER":"$HTTP_PASS" \
      -useragent "$USER_AGENT" -maxtime "$MAX_SCAN_SECONDS" -Format txt \
      -o "$OUT2" -timeout "$TIMEOUT" -T x6;

      SCAN_T="$(($SECONDS - $START_T))";
      echo "Nikto scan took "$SCAN_T" seconds.";
      break;;
    [Nn]* )
      break;;
    * ) echo "Please answer 'y' or 'n'.";;
  esac
done

###########################################
# RUN WAPITI SCAN                         #
###########################################
echo "";
while true; do
  read -p "Do you want to run a Wapiti scan (y/n)? " yn
  case $yn in
    [Yy]* ) 
      rm /home/"$USER"/.wapiti/scans -rf;
      START_T="$SECONDS";

      wapiti "$URL""$TARGET" -n 1 -b folder -f txt -o "$OUT3" -v 2 -t "$TIMEOUT" \
      --auth "$HTTP_USER"%"$HTTP_PASS" -u --verify-ssl 0 -m "common:post";

      SCAN_T="$(($SECONDS - $START_T))";
      echo "Wapiti scan took "$SCAN_T" seconds.";
      break;;
    [Nn]* ) 
      break;;
    * ) echo "Please answer 'y' or 'n'.";;
  esac
done

###########################################
# RUN ARACHNI SCAN                        #
###########################################
echo "";
while true; do
  read -p "Do you want to run an Arachni scan (y/n)? " yn
  case $yn in
    [Yy]* )
      START_T="$SECONDS";

      arachni --http-request-timeout ""$TIMEOUT"00" --http-user-agent="$USER_AGENT" \
      --output-only-positives --http-authentication-username "$HTTP_USER" \
      --http-authentication-password "$HTTP_PASS" "$URL""$TARGET"|tee "$OUT4";

      SCAN_T="$(($SECONDS - $START_T))";
      echo "Arachni scan took "$SCAN_T" seconds.";
      break;;
    [Nn]* )
      break;;
    * ) echo "Please answer 'y' or 'n'.";;
  esac
done


###########################################
# RUN W3AF SCAN                           #
###########################################
cat > "$W3AF_SCRIPT" <<EOF
http-settings
max_requests_per_second 10
set timeout $TIMEOUT
set user_agent $USER_AGENT
set basic_auth_user $HTTP_USER
set basic_auth_password $HTTP_PASS
set basic_auth_domain $TARGET
back
misc-settings
set max_discovery_time $MAX_SCAN_MINUTES
set fuzz_cookies True
set fuzz_form_files True
set fuzz_url_parts True
set fuzz_url_filenames True
back
plugins
crawl pykto,robots_txt,sitemap_xml,web_spider
audit blind_sqli,csrf,dav,eval,format_string,generic,os_commanding,sqli,ssi,un_ssl,xss,xst
infrastructure allowed_methods,domain_dot,dot_net_errors,server_header,server_status
auth generic
grep analyze_cookies,code_disclosure,credit_cards,directory_indexing,error_500,error_pages,get_emails,path_disclosure,private_ip,strange_headers,strange_http_codes,strange_parameters,strange_reason
grep config get_emails
set only_target_domain False
back
output console,text_file
output config text_file
set output_file $OUT5
set verbose False
back
output config console
set verbose False
back
back
target
set target $URL$TARGET
back
start
EOF

echo "############################" >"$TMP1";
echo "###      NMAP SCAN      ####" >>"$TMP1";
echo "############################" >>"$TMP1";
echo "############################" >"$TMP2";
echo "###      NIKTO SCAN     ####" >>"$TMP2";
echo "############################" >>"$TMP2";
echo "############################" >"$TMP3";
echo "###     WAPITI SCAN     ####" >>"$TMP3";
echo "############################" >>"$TMP3";
echo "############################" >"$TMP4";
echo "###    ARACHNI SCAN     ####" >>"$TMP4";
echo "############################" >>"$TMP4";
echo "############################" >"$TMP5";
echo "###      W3AF SCAN      ####" >>"$TMP5";
echo "############################" >>"$TMP5";

echo "";
while true; do
  read -p "Do you want to run a W3AF scan (y/n)? " yn
  case $yn in
    [Yy]* )
      START_T="$SECONDS";

      w3af_console -s "$W3AF_SCRIPT";

      SCAN_T="$(($SECONDS - $START_T))";
      echo "W3AF scan took "$SCAN_T" seconds.";
      break;;
    [Nn]* )
      break;;
    * ) echo "Please answer 'y' or 'n'.";;
  esac
done

###########################################
# CREATE A RESULTS FILE                   #
###########################################
sed -i -n '/vulnerability/p' "$OUT5";

cat "$TMP1" "$OUT1" "$TMP2" "$OUT2" "$TMP3" "$OUT3" "$TMP4" \
"$OUT4" "$TMP5" "$OUT5" >"$OUTRESULT";

rm -f "$TMP1" "$TMP2" "$TMP3" "$TMP4" "$TMP5" \
"$OUT1" "$OUT2" "$OUT3" "$OUT4" "$TMP5" "$OUT5" \
"$W3AF_SCRIPT";

echo -e "View the log report by issuing:\nless "$OUTRESULT"";

exit 0
