#!/bin/sh

DIRNAME=`dirname "$0"`
PROGNAME=`basename "$0"`

RUNTIME_FOLDER=`cd "$DIRNAME/.."; pwd`
BASE_FOLDER=`cd "$RUNTIME_FOLDER/.."; pwd`

# set ports for HTTP(S) serverputt
if [ "x$HTTP_PORT" = "x" ]; then
    HTTP_PORT="8080"
fi

if [ "x$HTTPS_PORT" = "x" ]; then
    HTTPS_PORT="8443"
fi

# Check Java version. Make sure java command is available
echo "Using java: $JAVA_HOME" && `java -version`
VERSION=`java -version 2>&1  | egrep '"([0-9].[0-9]\..*[0-9]).*"' | awk '{print substr($3,2,length($3)-2)}' | awk '{print substr($1, 3, 3)}' | sed -e 's;\.;;g'`
if [ "$VERSION" -lt "80" ]; then
   echo "ERROR: JVM must be greater than 1.7"
   exit 1;
fi

# Find the concierge framework jar
MAIN=$(find framework -name "org.eclipse.concierge-5.0.0*.jar" | sort | tail -1);

# Start the framework. Make sure java command is available
java $JAVA_OPTS \
	-Dosgi.clean=true \
	-Dorg.osgi.framework.storage="$BASE_FOLDER/userdata/storage" \
	-Dosgi.noShutdown=true \
	-Declipse.ignoreApp=true \
	-Dsmarthome.servicepid=org.eclipse \
	-Dsmarthome.logdir="$BASE_FOLDER/userdata/logs" \
	-Dsmarthome.userdata="$BASE_FOLDER/userdata" \
	-Dsmarthome.servicecfg="$RUNTIME_FOLDER/etc/services.cfg" \
	-Dlogback.configurationFile="$RUNTIME_FOLDER/etc/logback_debug.xml" \
	-Dorg.quartz.properties="$RUNTIME_FOLDER/etc/quartz.properties" \
	-DmdnsName=smarthome \
	-Djetty.home="$RUNTIME_FOLDER"/ \
	-Djetty.etc.config.urls=etc/jetty.xml,etc/jetty-deployer.xml,etc/jetty-selector.xml \
	-Dorg.osgi.service.http.port=$HTTP_PORT \
	-Dorg.osgi.service.http.port.secure=$HTTPS_PORT \
	-Dfelix.fileinstall.dir="$BASE_FOLDER/addons" \
	-Djava.library.path=lib \
	-Dfelix.fileinstall.active.level=4 \
	-Djava.awt.headless=true \
	-Dfile.encoding="UTF-8" \
	-jar $MAIN "$DIRNAME/smarthome.xargs"
