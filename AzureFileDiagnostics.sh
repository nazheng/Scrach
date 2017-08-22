#! /bin/bash

#global variables
PROG="${0##*/}"
UNCPATH=''
ACCOUNT=''
SHARE=''
ENVIRONMENT='AzureCloud'
SAFQDN=''
IPREGION=''


## print the log in custom format <to do: add color support>
print_log()
{

case  "$2" in
info)
  echo '[RUNNNG]--------' "${1}"
   ;;
warning)
  echo '[WARNING]-------' "${1}"
   ;;
error)
  echo '[ERROR]---------' "${1}"
   ;;
*)
  echo '[RUNNNG]--------' "${1}"
   ;;
esac

}


## ======================================Parse the arguments if it is non-empty=====================================================

## script usage function
usage()
{
    echo "options below are optional"
    echo '-u | --uncpath <value> Specify Azure File share UNC path like \\storageaccount.file.core.windows.net\sharename. if this option is provided, below options are ignored'
    echo '-a | --account <value> Specify Storage Account Name'
    echo '-s | --share <value >Specify the file share name'
    echo '-e | --azureenvironment <value> Specify the Azure environment. Valid values are: AzureCloud, AzureChinaCloud, AzureGermanCloud, AzureUSGovernment. The default is AzureCloud'
}


## When invoking script by sh, by default on ubunntu /bin/sh is mapped to DASH which has many constraints on scripting (e.g. DASH does not support array). But so checking SHELL version first. 
if [ -z $BASH_VERSION ]; then
   print_log "current SHELL is not BASH. please use bash to run this script" "error"
   exit 1
fi


if [ $# -gt 0 ] ; then


 ## Detect if system has enhanced getopt
 NEWGETOPT=false
 getopt -T >/dev/null

 if [ $? -eq 4 ]; then
    NEWGETOPT=true
 fi

 SHORT_OPTS=u:a:s:e:h
 LONG_OPTS=uncpath:,storageaccount:,share:,azureenvironment:,help

 ## Use getopt to sanitize the arguments first.
 if [ "$NEWGETOPT" ]; then
   ARGS=`getopt --name "$PROG" --long $LONG_OPTS --options $SHORT_OPTS -- "$@"`
 else
   ARGS=`getopt $SHORT_OPTS "$@"`
 fi

 if [ $? != 0 ] ; then
     echo "Usage error (use -h or --help for help)"
     exit 2
 fi

 eval set -- $ARGS
 
 ## Process parsed options
 echo "$@"
 while [ $# -gt 0 ]; do
    case "$1" in
        -u | --uncpath)   UNCPATH="$2"; shift;;
        -a | --account)  ACCOUNT="$2"; shift;;
        -s | --share)  SHARE="$2"; shift;;
        -e | --azureenvironment)  ENVIRONMENT="$2"; shift;;
        -h | --help)
         usage
         exit 0;;
        esac
    shift
 done

 ## make sure required options are specified.
 if ( [ -n "$UNCPATH" ] ); then
  print_log  "UNC path option is specified, other options will be ignored (use -h or --help for help)" "warning"
  UNCPATH=$(echo "$UNCPATH" | sed    's/\\/\//g')
  SAFQDN=$(echo "$UNCPATH" | sed 's/[\/\\]/ /g' | awk '{print $1}' ) 

 elif  ( [ -z "$UNCPATH" ] && (  [ -n "$ACCOUNT" ]  && [  -n "$SHARE" ] && [ -n "$ENVIRONMENT" ] ) ); then

  print_log  "Form the UNC path based on the options specified" "info"

  SUFFIX=''
  case "$ENVIRONMENT" in 
     azurecloud) SUFFIX='.file.core.windows.net' ;;
     azurechinacloud) SUFFIX='.file.core.chinacloudapi.cn' ;;
     azureusgovernment) SUFFIX='.file.usgovcloudapi.net' ;;
     AzureGermanCloud) SUFFIX='.file.core.cloudapi.de' ;;
  esac
  SAFQDN="$ACCOUNT""$SUFFIX"
  UNCPATH="//""$SAFQDN""/""$SHARE"

 else
  print_log  "$PROG: missing options (use -h or --help for help)"  "error"
  exit 2
 fi

fi


## ================================Client Side Environment validation =======================================

## simple function to compare version,echo has different implementatoin in SHELL, use printf to avoid compatability issue. 
ver_gt() { test "$(printf  "$1\n$2"  | sort -V | head -n 1)" != "$1"; }
ver_lt() { test "$(printf  "$1\n$2"  | sort -V | head -n 1)" != "$2"; }


## Get IP range function
get-ip-region()
{

  #constant file name
xmlfile="azurepubliciprange.xml"

if [ ! -f "$xmlfile" ]; then

#get the download file path
curl -o download.html -s https://www.microsoft.com/en-us/download/confirmation.aspx?id=41653
RET=$(cat download.html | grep -o 'https://download\.microsoft\.com[a-zA-Z0-9_/\-]*\.xml' | head -n 1)


#download the file into local file
print_log '+++ downloading Azure Public IP range XML file' "info"
curl -o "$xmlfile" -s "$RET"

fi

RET=$(cat "$xmlfile" | awk -v ipaddr="$1" '

#function to verify if IP network address matches with the IP range
function IpInRange(iprange, ipaddr)
{

 #printf "Checking IP address %s in IP Range %s\n", ipaddr, iprange

 split(iprange, a, "/")

 subnetaddr=a[1]
 cidrlen=a[2]

 tmp=32-cidrlen
 ipmax=lshift(1,32)-1
 mask=and((compl(lshift(1,tmp)-1)),ipmax)

 split(ipaddr, b, ".")
 ipnetdec = (b[1] * 2^24) + (b[2] * 2^16) + (b[3] * 2^8) + b[4]

 split(subnetaddr, b, ".")
 subnetdec = (b[1] * 2^24) + (b[2] * 2^16) + (b[3] * 2^8) + b[4]


 ipnet=and(ipnetdec, mask)
 subnet=and(subnetdec,mask)

 return (subnet == ipnet)
}

BEGIN{ region = "" }

/Region Name/ { split($0, a, "\""); region=a[2]}

/IpRange/ {split($0, a, "\""); ret=IpInRange(a[2], ipaddr); if (ret) {print  region} }

')

IPREGION="$RET"

}


## verify the SMB Encrption support. 
print_log "Verify SMB Encryption support " "info"

DISTNAME=''
DISTVER=''
KERVER=''

DISTNAME=$(uname -a | grep -o -i ubuntu)
KERVER=$(uname -r | cut -d - -f 1)

## Ubuntu OS checks the distribution version
if [ -n "$DISTNAME" ]; then

 DISTVER=$(lsb_release -d | grep -o \\b[0-9\\.]\\+\\b)
 print_log  "Ubuntu distribution version  is  "$DISTVER" "  "info"
 ver_lt "$DISTVER" "16.04"


 if [ $? -eq 0 ] ; then
   print_log "system DOES NOT support SMB Encryption"  "warning"
   SMB3=0
 else
   print_log "system supports SMB Encryption" "info"
   SMB3=1
 fi

## Other distributions check kernel versions. 
else

 print_log  "Linux kernel version is  "$KERVER" "  "info"
 ver_lt "$KERVER" "4.11.0"

 if [ $? -eq 0 ]; then   
   print_log "system DOES NOT support SMB Encryption"  "warning"
   SMB3=1
 else
   print_log "system supports SMB Encryption" "info"
   SMB3=0
 fi
fi


## Check if system has fix for known idle timeout/reconnect issues, not terminate error though. 
if  ( ver_gt "$KERVER"  "4.9.1" ) || ( ( ver_gt "$KERVER"  "4.8.15" ) &&  ( ver_lt "KEVER" "4.9.0" ) ) || ( ( ver_gt "$KERVER"  "4.4.39" )  &&  ( ver_lt "KEVER" "4.5.0") )  ; then
 print_log "Kernel has been patched with the fixes that prevent idle timeout issues" "info"
else
 print_log "Kernel has not been patched with the fixes that prevent idle timeout issues, more information, please refer to https://docs.microsoft.com/en-us/azure/storage/storage-troubleshoot-linux-file-connection-problems#mount-error112-host-is-down-because-of-a-reconnection-time-out" "warning"
fi

## Prompt user for UNC path if no options are provided.
if  [ -z "$SAFQDN" ]; then
  print_log "type the storage account name, followed by [ENTER]:"  'info'
  read ACCOUNT

  print_log "type the share path, followed by [ENTER]:" "info"
  read SHARE

  print_log "choose the Azure Environment:"  "info"
  PS3='Please enter your choice: '
  SUFFIX=''
  ## SH points to /bib/dash on ubuntu system, but dash does not support array/select. 
  options=('azurecloud' 'azurechinacloud' 'azuregermancloud' 'azureusgovernment')

  select opt in "${options[@]}"
  do
    case $opt in
        "azurecloud")
            SUFFIX=".file.core.windows.net"
            break
            ;;
        "azurechinacloud")
            SUFFIX=".file.core.chinacloudapi.cn"
            break
            ;;
        "azuregermancloud")
            SUFFIX=".file.core.cloudapi.de"
            break
            ;;
        "azureusgovernment")
           SUFFIX=".file.usgovcloudapi.net"
           break
            ;;
        *) echo invalid option;;
    esac
  done
  SAFQDN="$ACCOUNT""$SUFFIX"
  UNCPATH="//""$SAFQDN""/""$SHARE"
fi

print_log " storage account FQDN is "$SAFQDN"" "info"

## Verify port 445 reachability. 

if [ -n "$SAFQDN" ] ; then

   ## Netcat is not instaled by default on Redhat/CentOS, so use native BASH command to test the port reachability.
   command -v nc >/dev/null 2>&1  &&  RET=$(netcat -v -z -w 5 "$SAFQDN"  445 2>&1) ||  timeout 5 bash -c "echo >/dev/tcp/$SAFQDN/445" && RET='succeeded' || RET="Connection Timeout or Error happens"


   echo "$RET" | grep -i succeeded 

   if [ "$?" -eq  0 ] ; then
     print_log "Port 445 is reachable from this client." "info"
   else
     print_log "Port 445 is not reachable from this client and the error is ""$RET"  "error"
     exit 2
   fi
fi

## Verify  IP region if SMB encrytion is not supported.
if [ "$SMB3" -eq 1 ]; then
  DHCP25=''
  PIP=''
  SAIP=''
  ClientIPRegion=''
  SARegion=''

  ## verify client is Azure VM or not. On untuntu DHCP lease option can be used to check it but Red Hat does not seem to support it. Use client IP too. 
  grep -q unknown-245 /var/lib/dhcp/dhclient.eth0.leases  2&>1
  DHCP245=$?

  PIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
  get-ip-region "$PIP"

  ClientIPRegion="$IPREGION"

  if (  [  "$DHCP245" -eq 0 ]  || [  "$ClientIPRegion" != '' ] ); then
     print_log "client is Azure VM and running in region ""$ClientIPRegion" "info"

     SAIP=$(dig +short "$SAFQDN" | grep -o [0-9]\\+\.[0-9]\\+\.[0-9]\\+\.[0-9]\\+)
     get-ip-region "$SAIP"
     SARegion="$IPREGION"
     print_log "storage account region is ""$SARegion" "info"
     if [ "$SARegion" != "$ClientIPRegion" ] ; then
       print_log "Azure VM region mismatches with Storage Account Region, Please make sure Azure VM is in the same region as storage account. More information, please refer to https://docs.microsoft.com/en-us/azure/storage/storage-how-to-use-files-linux " "error"
       exit 2
     fi

  fi

fi



## ==============================map drive for user, start tcpdump in background.=======================================

## Function to Enable  CIFS debug logs including packet trace and CIFS kernel debug trace. 
enable_log()
{

 LOGDIR="MSFileMountDiagLog"

 if [ ! -d "$LOGDIR" ]; then
   mkdir "$LOGDIR"
 fi

 TCPLOG="./""$LOGDIR""/packet.cap"
 if [ -f "$TCPLOG" ] ; then
   rm -f "$TCPLOG"
 fi
 command="tcpdump -i any port 445  -w ""$TCPLOG"" &"
 sudo sh -c  "$command"
 command="echo 'module cifs +p' > /sys/kernel/debug/dynamic_debug/control;echo 'file fs/cifs/* +p' > /sys/kernel/debug/dynamic_debug/control;echo 1 > /proc/fs/cifs/cifsFYI"
 sudo sh -c  "$command"
}


## Function to disable logging.
disable_log()
{
 PID=$(sudo pgrep tcpdump)
 sudo kill "$PID"

 command="echo 'module cifs -p' > /sys/kernel/debug/dynamic_debug/control;echo 'file fs/cifs/* -p' > /sys/kernel/debug/dynamic_debug/control;echo 0 > /proc/fs/cifs/cifsFYI"
 sudo sh -c  "$command"
 CIFSLOG="./""$LOGDIR""/cifs.txt" 
 cp /var/log/kern.log  "$CIFSLOG"
}

## Prompt user to select diagnostics option
print_log "Do you want to tun on diagnostics logs"

options=("yes" "no")

  select opt in "${options[@]}"
  do
    case $opt in
        yes)
	    #comform to BASH, 0 means true. 
            DIAGON=0
            break
            ;;
        no)
            DIAGON=1
            break
            ;;
        *) echo please type yes or no;;
    esac
  done

if [ "$DIAGON" -eq 0 ]; then
   enable_log  
fi


## Prompt user to type the local mount point and storage account access key. 
print_log "type the local mount point, followed by [ENTER]:" "info"
read mountpoint

if [ ! -d "$mountpoint" ] ;then
  mkdir "$mountpoint"
fi

print_log "type the storage account access key, followed by [ENTER]:" "info"
read password

username=$( echo "$SAFQDN" | cut -d '.' -f 1)

command="mount -t cifs "$UNCPATH"  "$mountpoint" -o vers=3.0,username="$username",password="$password",dir_mode=0777,file_mode=0777,sec=ntlmssp"
sudo sh -c "$command"
sleep 1

if [ "$DIAGON" -eq 0 ]; then
   disable_log
fi













