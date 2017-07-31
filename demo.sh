#! /bin/bash

function ver_gt() { test "$(echo -e "$1\n$2"  | sort -V | head -n 1)" != "$1"; }
function ver_lt() { test  "$(echo -e "$1\n$2"  | sort -V | head -n 1)" == "$1"; }

echo +++  demo strating....
echo
echo +++  UNC path is "$1"
echo

#verify the port connectivity

HOSTPATH=$(echo ${1} | sed 's/[\/\\]/ /g' | awk '{print $1}' ) 

if [ -z  "${HOSTPATH}" ]
then
echo --- Cannot parse the UNC path correctly
echo
return 999
fi

echo "$HOSTPATH"

RET=$(netcat -v -z -w 5 "$HOSTPATH"  445 2>&1)

echo $RET | grep -i succeeded

if [ $? == 0 ]
then
   echo +++ Port 445 is reachable from this client.
else
   echo ---  Port 445 is not reachable from this client and the error is $RET
fi

echo 

#check the kernel version to determine the SMB version and known issues.

KERVER=$(uname -r | cut -d '-' -f 1)

ver_gt "$KERVER"  "4.11" && echo client has kernel version greater than 4.11 and support smb30 encryption. 

ver_gt "$KERVER"  "4.9.0"  &&   echo client has the fix for known issues. 
ver_gt "$KERVER"  '4.8.15' &&   ver_lt "KEVER" '4.9.0' &&  echo client has the fix for konwn issues. 
ver_gt "$KERVER"  '4.4.39' &&   ver_lt "KEVER" '4.5.0' &&  echo client has the fix for konwn issues.

ver_lt "$KEVER" '4.4.40' && echo ---  client may have some issues with old kernel version than 4.4.40


echo
if `grep -q unknown-245 /var/lib/dhcp/dhclient.eth0.leases`; then
    echo +++  VM running in an Azure VM
fi

echo
PIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
echo +++  vm publit IP is "$PIP"
echo
echo +++  demo stopping

