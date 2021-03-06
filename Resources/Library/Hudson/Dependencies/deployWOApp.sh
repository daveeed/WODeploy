#!/bin/bash
# Call this from Hudson to deploy a build on the same server
# This script assumes you are archiving the .tar.gz files

THE_APP_NAME=${JOB_NAME}
THE_HOST_NAME=`hostname`
JAVAMONITOR_PORT="56789"
HTTP="http"
WEBAPP_LOCATION=/Library/WebObjects/Applications
WEBSERVER_LOCATION=/Library/WebServer/Documents/WebObjects

if [ -z ${JOB_NAME} ] ; then
	JOB_NAME="\$JOB_NAME"
fi

while getopts a:h:p:P:A:W:s o
do	case "$o" in
	a) THE_APP_NAME="$OPTARG";;
	h) THE_HOST_NAME="$OPTARG";;
	p) JAVAMONITOR_PW="$OPTARG";;
	P) JAVAMONITOR_PORT="$OPTARG";;
	s) HTTP="https";;
	[?])	echo >&2 -e "Usage: $0 \n\t[-a App Name (Default =  ${JOB_NAME})] \n\t[-h Host Name (Default = ${THE_HOST_NAME})] \n\t[-p JavaMonitor Password] \n\t[-P JavaMonitor Port (Default = 56789)] \n\t[-s (JavaMonitor will use https instead http)] \n\t[-A App Location (Default = /Library/WebObjects/Applications)] \n\t[-W Web Doc Location (Default = /Library/WebServer/Documents/WebObjects)]"
		exit 1;;
	esac
done


JAVAMONITOR_URL=${HTTP}://${THE_HOST_NAME}:${JAVAMONITOR_PORT}/cgi-bin/WebObjects/JavaMonitor.woa
JAVAMONITOR_URL=${HTTP}://${THE_HOST_NAME}/WOMonitor

echo -e "\n"
echo -e "deploy:\n"
echo "Starting ${THE_APP_NAME}.woa deployment on ${THE_HOST_NAME}"
##############
# Copy the new app, and restart the app instance.
##############
# Remove the old tar.gz just in case
rm -f ${WEBAPP_LOCATION}/${THE_APP_NAME}-Application.tar.gz

# Copy the fresh tar.gz from the archive to the WO app folder
echo "Copying ${THE_APP_NAME}-Application.tar.gz to Applications"
cp ${WORKSPACE}/../builds/${BUILD_NUMBER}/archive/dist/${THE_APP_NAME}-Application.tar.gz ${WEBAPP_LOCATION}/ 

# Turn off autorecover on the app, then shut it down
echo "Turning off autorecover for ${THE_APP_NAME}.woa -> "
curl -s ${JAVAMONITOR_URL}/admin/turnAutoRecoverOff?pw=${JAVAMONITOR_PW}\&type=app\&name=${THE_APP_NAME}
echo -e "\nShutting down ${THE_APP_NAME}.woa -> "
curl -s ${JAVAMONITOR_URL}/admin/stop?pw=${JAVAMONITOR_PW}\&type=app\&name=${THE_APP_NAME}
echo -e "\n"
# Remove the previous backup
rm -f -r ${WEBAPP_LOCATION}/${THE_APP_NAME}_old.woa

# Move the current .woa to the newest backup (if it exists)
echo "Backing up the old app to ${THE_APP_NAME}_old.woa"
if [ -d ${WEBAPP_LOCATION}/${THE_APP_NAME}.woa ] ; then
  mv -f ${WEBAPP_LOCATION}/${THE_APP_NAME}.woa ${WEBAPP_LOCATION}/${THE_APP_NAME}_old.woa
fi

# Untar the app
echo "Untarring ${THE_APP_NAME}-Application.tar.gz"
cd ${WEBAPP_LOCATION}/
tar -xzf ${WEBAPP_LOCATION}/${THE_APP_NAME}-Application.tar.gz

# Fix permissions
chown -R _appserver:_appserveradm ${WEBAPP_LOCATION}/${THE_APP_NAME}.woa

# Turn on the app and turn on autorecover
echo "Starting up ${THE_APP_NAME}.woa -> "
curl -s ${JAVAMONITOR_URL}/admin/start?pw=${JAVAMONITOR_PW}\&type=app\&name=${THE_APP_NAME}
echo -e "\nTurning on autorecover for ${THE_APP_NAME}.woa -> "
curl -s ${JAVAMONITOR_URL}/admin/turnAutoRecoverOn?pw=${JAVAMONITOR_PW}\&type=app\&name=${THE_APP_NAME}
echo -e "\n"

# Remove the .tar.gz 
rm -f ${WEBAPP_LOCATION}/${THE_APP_NAME}-Application.tar.gz


##############
# Copy the new app's web server resources.
##############

# Remove the old tar.gz just in case
rm -f ${WEBSERVER_LOCATION}/${THE_APP_NAME}-WebServerResources.tar.gz

# Copy the fresh tar.gz from the archive to the WO app folder
echo "Copying ${THE_APP_NAME}-WebServerResources.tar.gz to WebServer Documents"
cp ${WORKSPACE}/../builds/${BUILD_NUMBER}/archive/dist/${THE_APP_NAME}-WebServerResources.tar.gz ${WEBSERVER_LOCATION}/ 

# Remove the previous backup
rm -f -r ${WEBSERVER_LOCATION}/${THE_APP_NAME}_old.woa

# Move the current .woa to the newest backup
echo "Backing up the old webserver resources to ${THE_APP_NAME}_old.woa"
if [ -d ${WEBSERVER_LOCATION}/${THE_APP_NAME}.woa ] ; then
  mv -f ${WEBSERVER_LOCATION}/${THE_APP_NAME}.woa ${WEBSERVER_LOCATION}/${THE_APP_NAME}_old.woa
fi

# Untar the app
echo "Untarring ${THE_APP_NAME}-WebServerResources.tar.gz"
cd ${WEBSERVER_LOCATION}/
tar -xzf ${WEBSERVER_LOCATION}/${THE_APP_NAME}-WebServerResources.tar.gz

# Fix permissions
#chown -R apache:apache ${WEBSERVER_LOCATION}/${THE_APP_NAME}.woa

# Remove the .tar.gz 
rm -f ${WEBSERVER_LOCATION}/${THE_APP_NAME}-WebServerResources.tar.gz

echo "${THE_APP_NAME}.woa succesfully deployed"
echo -e "\n\n"

exit 0;