#! /bin/bash

i='5000'

while [ $i -lt 7000 ]
do 
	dd if=/dev/urandom bs=1024 count=1 of="$i.txt"
	echo write "$i.txt" file. 
	i=$[$i + 1]

done
