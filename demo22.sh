#! /bin/bash

#global variables
PROG="${0##*/}"
UNCPATH=''
ACCOUNT=''
SHARE=''
ENVIRONMENT='AzureCloud'

## simple function to compare version,echo has different implementatoin in SHELL, use printf to avoid compatability issue. 
ver_gt() { test "$(printf  "$1\n$2"  | sort -V | head -n 1)" != "$1"; }
ver_lt() { test "$(printf  "$1\n$2"  | sort -V | head -n 1)" != "$2"; }

## print the log in custom format <to do: add color support>
print_log()
{
case  "$2" in
info)
  echo '[RUNNNG]------' "${1}"
   ;;
warning)
  echo '[WARNING]------' "${1}"
   ;;
error)
  echo '[ERROR]------' "${1}"
   ;;
esac
}


## script usage
usage()
{
    echo "options below are optional"
    echo '-u | --uncpath <value> Specify Azure File share UNC path like \\storageaccount.file.core.windows.net\sharename. if this option is provided, below options are ignored'
    echo '-a | --account <value> Specify Storage Account Name'
    echo '-s | --share <value >Specify the file share name'
    echo '-e | --azureenvironment <value> Specify the Azure environment. Valid values are: AzureCloud, AzureChinaCloud, AzureUSGovernment. The default is AzureCloud'
}



## Parse the arguments if it is non-empty
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
     return 2
fi

eval set -- $ARGS
print_log "system supports SMB Encryption" "info" ||
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
         return 0;;
        esac
    shift
done

## make sure required options are specified.
if ( [ -n "$UNCPATH" ] ); then
  echo "UNC path option is specified, other options will be ignored (use -h or --help for help)"
elif  ( [ -z "$UNCPATH" ] && (  [ -n "$ACCOUNT" ]  && [  -n "$SHARE" ] && [ -n "$ENVIRONMENT" ] ) ); then
  echo "Form the UNC path based on the options specified"
else
 echo "$PROG: missing options (use -h or --help for help)" >&2
  return 2
fi

fi


## verify the SMB Encrption support. 
print_log "Verify SMB Encryption support " "info"

DISTNAME=''
DISTVER=''
KERVER=''

## Ubuntu OS checks the distribution version
DISTNAME=$(lsb_release -d | grep -o -i ubuntu)
KERVER=$(uname -r | cut -d - -f 1)

if [ -n "$DISTNAME" ]; then

 DISTVER=$(lsb_release -d | grep -o \\b[0-9\\.]\\+\\b)
 print_log  "Ubuntu distribution version  is  "$DISTVER" "  "info"
 ver_lt "$DISTVER" "16.4.0"


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
   SMB3=0
 else
   print_log "system supports SMB Encryption" "info"
   SMB3=1
 fi
fi


## Prompt user for UNC path if no options are provided.
ver_gt "$KERVER"  "4.9.1"

## Verify port 445 reachability. 

## Verify  IP region if SMB encrytion is not supported.

## Map drive 

if [ "$SMB3" -eq 0 ]; then
  if `grep -q unknown-245 /var/lib/dhcp/dhclient.eth0.leases`; then
    print_log "VM running on Azure" "info"
  fi
  
fi











