#!/bin/bash


input="ip.xml"

subnet=''
region==''
ipaddr=''

ipaddr="52.253.192.1"

date +%H:%M:%S:%N

while IFS= read -r var

do


if  [[ $var =~  'Region Name' ]]; then
   a=(${var//\"/ })
   region=${a[2]}
fi

cidraddr=''

if [[ $var =~ 'IpRange Subnet' ]]; then
   a=(${var//\"/ })
   cidraddr=${a[2]}
  
fi


if [[ -n "$cidraddr" ]]; then

 a=(${cidraddr/\// })
 subnet=${a[0]}

 cidrlen=${a[1]}
 let "tmp=1<<(32-$cidrlen), tmp--"
 let "fullone=1<<32 , fullone--"
 let "mask=$tmp ^ $fullone"
 
 a=(${ipaddr//./ })
 let "ipnetdec=${a[0]} * 16777216 + ${a[1]} * 65536 + ${a[2]} * 256 + ${a[3]}"
  
 a=(${subnet//./ })
 let "subnetdec=${a[0]} * 16777216 + ${a[1]} * 65536 + ${a[2]} * 256 + ${a[3]}"

 let "ipnetdec=$ipnetdec & $mask"
 
 if [[ $subnetdec -eq $ipnetdec ]]; then 
   match=1
   break
 fi

fi

done < "$input"

date +%H:%M:%S:%N

if [[ $match -eq 1 ]];then

 echo $region

fi
