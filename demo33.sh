#!/bin/bash
input="ip.xml"

subnet=''
region==''
ipaddr=''

ipaddr="52.253.192.1"

while IFS= read -r var

do

echo "$var" | grep 'Region Name'   >/dev/null 2>&1 && region=$(echo "$var" | cut -d '"' -f 2 )
subnet=''
echo "$var" | grep 'IpRange Subnet'   >/dev/null 2>&1 && subnet=$(echo "$var" | cut -d '"' -f 2 )

if [[ -n "$subnet" ]]; then

#echo $region
#echo $subnet

 a=($(echo "$subnet" | sed 's/\// /g'))

 subnetaddr=${a[0]}
 cidrlen=${a[1]}

 let "tmp = 1<< (32-$cidrlen), tmp--"
 let "fullone = 1<<32 , fullone--"
 let "mask= $tmp ^ $fullone"

 a=($(echo "$ipaddr" | sed 's/\./ /g'))
 let "ipnetdec = ${a[0]} * 16777216 + ${a[1]} * 65536 + ${a[2]} * 256 + ${a[3]}"

 a=($(echo "$subnetaddr" | sed 's/\./ /g'))
 let "subnetdec = ${a[0]} * 16777216 + ${a[1]} * 65536 + ${a[2]} * 256 + ${a[3]}"

 let "ipnet=$ipnetdec & $mask"
 let "subnet=$subnetdec & $mask"

 let " $subnet == $ipnet "
 
 if [[ $? -eq 0 ]]; then
   match=1
   break
 fi

fi

done < "$input"

if [[ $match -eq 1 ]];then

 echo $region

fi
