#!/bin/ash
logdir=/root/logs/
for i in $(ls $logdir | tr "\n" " ")
do
	if [ $(du $logdir/$i | cut -d "/" -f 1 ) -gt "100" ]; then
		if [ -f $logdir/$i.tgz ]; then	zcat $logdir/$i.tgz > /tmp/$i ; fi
		cat $logdir/$i >> /tmp/$i
		tar -czvf $logdir/$i.tgz /tmp/$i
		rm /tmp/$i
		rm $logdir/$i
	fi	

done	

