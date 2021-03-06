#!/bin/bash
DO_DOWNLOAD="true"
WEBSERVER_LOCATION=/Library/WebServer/Documents/WebObjects
WEBOBJECTS_LOCATION=/Library/WebObjects/Applications

WOMONITOR_APP="JavaMonitor.woa"
WOMONITOR="${WOMONITOR_APP}.tar.gz"
PREVIOUS_WOMONITOR="${WOMONITOR_APP}.tar.gz.previous"

WOTASKD_APP="wotaskd.woa"
WOTASKD="${WOTASKD_APP}.tar.gz"
PREVIOUS_WOTASKD="${WOTASKD_APP}.tar.gz.previous"

while getopts d o
do	case "$o" in
	d) DO_DOWNLOAD="false";;
	[?])	echo >&2 -e "Usage: $0 \n\t[-d Don't download files (Default =  true] "
		exit 1;;
	esac
done

echo "Upgrading WOMonitor and WOTaskd..."

#
#Download the latest build of JavaMonitor (renamed to WOMonitor) and WOTaskd
#
if [ ${DO_DOWNLOAD} == "true" ]; then
	echo "Downloading WOMonitor"
	cd /tmp
	rm -f ${WOMONITOR}
	curl http://webobjects.mdimension.com/hudson/job/Wonder54/lastSuccessfulBuild/artifact/dist/JavaMonitor.woa.tar.gz -L -# -o  ${WOMONITOR}
	echo "Downloading WOTaskd"
	rm -f ${WOTASKD}
	curl http://webobjects.mdimension.com/hudson/job/Wonder54/lastSuccessfulBuild/artifact/dist/wotaskd.woa.tar.gz -L -# -o ${WOTASKD}
else
	echo "Skiping Download"
fi

cd ${WEBOBJECTS_LOCATION}

#
#Install WOMonitor
#
echo "Installing WOMonitor"
if [ ${DO_DOWNLOAD} == "true" ] ; then 
	rm -f ${PREVIOUS_WOMONITOR}
	if [ -a ${WOMONITOR} ] ; then 
		mv -f ${WOMONITOR} ${PREVIOUS_WOMONITOR}
	fi
	mv /tmp/${WOMONITOR} ${WOMONITOR}
fi
rm -fr ${WOMONITOR_APP}
tar xfz ${WOMONITOR}
#Add Rewrite Rule
REWRITE_RULE="\n\ner.extensions.ERXApplication.replaceApplicationPath.pattern=/cgi-bin/WebObjects/${WOMONITOR_APP}\ner.extensions.ERXApplication.replaceApplicationPath.replace=/WOMonitor\n"=
echo -e ${REWRITE_RULE} >> ${WOMONITOR_APP}/Contents/Resources/Properties
#Fix Permissions
chown -R _appserver:_appserveradm ${WOMONITOR_APP}


#
#Install WOTaskD
#
echo "Installing wotaskd"
if [ ${DO_DOWNLOAD} == "true" ] ; then 
	rm -f ${PREVIOUS_WOTASKD}
	if [ -a ${WOTASKD} ] ; then 
		mv -f ${WOTASKD} ${PREVIOUS_WOTASKD} 
	fi
	mv /tmp/${WOTASKD} ${WOTASKD}
fi
rm -fr ${WOTASKD_APP}
tar xfz ${WOTASKD}
#Make sure SpawnOfWotaskd.sh/javawoservice.sh are executable
chmod a+x ${WOTASKD_APP}/Contents/Resources/SpawnOfWotaskd.sh
chmod a+x ${WOTASKD_APP}/Contents/Resources/javawoservice.sh
#Fix Permissions
chown -R _appserver:_appserveradm ${WOTASKD_APP}


#
#Instal WOMonitor WebServer Resources
#
echo "Installing WOMonitor WebServer Resources"
cd ${WEBSERVER_LOCATION}
rm -fr ${WOMONITOR_APP}
tar -xzf ${WEBOBJECTS_LOCATION}/${WOMONITOR} ${WOMONITOR_APP}/Contents/WebServerResources/*
#Fix Permissions
chown -R apache:apache ${WOMONITOR_APP}



#
#Restart wotaskd
echo "Restarting WOTaskd"
sudo launchctl stop com.webobjects.wotaskd

exit 0;