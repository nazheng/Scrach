#! /bin/bash

PIP=$(dig +short myip.opendns.com @resolver1.opendns.com)


cat iprange.xml | awk -v ipaddr="$PIP" '



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


BEGIN {print "*** Start parsing XML file and look for the region for " ipaddr ; } 

/Region Name/ { split($0, a, "\""); region=a[2]; print "checking region " region } 

/IpRange/ {split($0, a, "\""); ret=IpInRange(a[2], ipaddr); if (ret) {print "+++ Match! IP region is " region;exit} } 

END {print "*** Complete XML parsing";}

'
