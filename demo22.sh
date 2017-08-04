#! /bin/bash

#global variables
PROG="${0##*/}"
UNCPATH=''
ACCOUNT=''
SHARE=''
ENVIRONMENT='AzureCloud'

## simple function to compare version
ver_gt() { test "$(echo -e "$1\n$2"  | sort -V | head -n 1)" != "$1" && return 0 || return 1; }
ver_lt() { test "$(echo -e "$1\n$2"  | sort -V | head -n 1)" != "$2" && return 0 || return 1; }

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


UBUNTUVER=$(lsb_release -d | grep -o \\b[0-9\\.]\\+\\b)

echo 'system version is  ' "$UBUNTUVER" 



ver_lt "$UBUNTUVER" "16.4.0"

if [ $? -eq 0 ]; then
  print_log "system DOES NOT support SMB Encryption"  "warning"
else
  print_log "system supports SMB Encryption" "info"
fi

