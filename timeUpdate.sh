#!/bin/sh

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

applicationPath=$(dirname $0)
timeZonePath=/usr/share/zoneinfo
RsyncServer=rsync://rsync.iana.org/tz/
timeZone=America/Santiago

tzTemp=${applicationPath}/tzTemp
tzBackup=${applicationPath}/tzBackup

hash make 2>/dev/null || { echo >&2 "'make' command required but not installed.  Aborting."; exit 1; }
hash rsync 2>/dev/null || { echo >&2 "'rsync' command required but not installed.  Aborting."; exit 1; }

tzDataCurrentPath=$(rsync -l ${RsyncServer}tzdata-latest.tar.gz | awk '{print $7}')
tzDataCurrentFile=$(echo $tzDataCurrentPath | awk -F"/" '{print $NF}')

tzCodeCurrentPath=$(rsync -l ${RsyncServer}tzcode-latest.tar.gz | awk '{print $7}')
tzCodeCurrentFile=$(echo $tzCodeCurrentPath | awk -F"/" '{print $NF}')

if [ ! -d "$tzBackup" ]; then
        mkdir "$tzBackup"
fi

if [ ! -f "$tzBackup/$tzDataCurrentFile" ] || [ ! -f "$tzBackup/$tzCodeCurrentFile" ] ; then

  if [ ! -d "$tzTemp" ]; then
        	mkdir "$tzTemp"
	fi
	
	cd "$tzTemp"

	rsync ${RsyncServer}${tzCodeCurrentPath} .
	rsync ${RsyncServer}${tzDataCurrentPath} .

	cp "$tzDataCurrentFile" "$tzBackup/$tzDataCurrentFile"
	cp "$tzCodeCurrentFile" "$tzBackup/$tzCodeCurrentFile"	

	gzip -dc ${tzDataCurrentFile} | tar -xf -
	gzip -dc ${tzCodeCurrentFile} | tar -xf -

	make "TOPDIR=`pwd`/bin-timezone" install > /dev/null 2>&1
	cp -fr ./bin-timezone/etc/zoneinfo/* ${timeZonePath}
	echo $timeZone > /etc/timezone
	cp -f "$timeZonePath/$timeZone" /etc/localtime
	cd ..
	rm -fr "$tzTemp"
	echo "Hora corriente : `date`"
fi
