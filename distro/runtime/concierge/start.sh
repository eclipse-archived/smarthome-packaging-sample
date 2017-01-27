#!/bin/sh

# Start script to run Eclipse SmartHome on Concierge
# This script allows you to:
#   * define your JavaVM via JAVA_HOME
#   * Set http and https port via HTTP_PORT, HTTPS_PORT. They defaults to 8080, 8443
#   * Check for minimal Java version: JavaSE 8, compact 2 profile
#   * when called with "debug" option as first argument:
#     * will enable Java Flight Recorder (for Oracle JVM only if installed)
#     * will enable JMX for remote monitoring (when running at least compact3 profile)
#
# Returned error codes:
#   1: $JAVA_HOME/bin/java not found
#   2: Java Version < 1.8
#   3: Java Compact 2 at least needed
#

DIRNAME=`dirname "$0"`
PROGNAME=`basename "$0"`

RUNTIME_FOLDER=`cd "$DIRNAME/.."; pwd`
BASE_FOLDER=`cd "$RUNTIME_FOLDER/.."; pwd`

# set ports for HTTP(S) server
if [ "x$HTTP_PORT" = "x" ]; then
    HTTP_PORT="8080"
fi
if [ "x$HTTPS_PORT" = "x" ]; then
    HTTPS_PORT="8443"
fi

# arg 0: debug enabled: true/false
findJvmVersion() {
    # use java from JAVA_HOME if set, otherwise java from path, e.g. default java on RaspPi
    JAVA_BIN=java
    if [ "x$JAVA_HOME" != "x" ] ; then
        JAVA_BIN=$JAVA_HOME/bin/java
        if [ ! -f $JAVA_BIN ] ; then
            echo "ERROR: could not find $JAVA_BIN"
            exit 1
        fi
    fi

    # Check Java version. Make sure java command is available
    JAVA_VERSION_OUTPUT=`$JAVA_BIN -version 2>&1`
    echo "Using java: $JAVA_BIN"
    echo "$JAVA_VERSION_OUTPUT"

    JAVA_VERSION=`echo $JAVA_VERSION_OUTPUT | egrep '"([0-9].[0-9]\..*[0-9]).*"' | awk '{print substr($3,2,length($3)-2)}' | awk '{print substr($1, 3, 3)}' | sed -e 's;\.;;g'`
    # get information about compact profile (1/2/3/fulljre) and Vendor (Oracle, Azul)
    JAVA_COMPACT_PROFILE="fulljre"
    JAVA_VENDOR="Oracle"

    IS_COMPACT1_PROFILE=`echo $JAVA_VERSION_OUTPUT | sed -e 's/^.*compact1.*$/true/g'`
    if [ "$IS_COMPACT1_PROFILE" = "true" ] ; then JAVA_COMPACT_PROFILE="compact1" ; fi
    IS_COMPACT2_PROFILE=`echo $JAVA_VERSION_OUTPUT | sed -e 's/^.*compact2.*$/true/g'`
    if [ "$IS_COMPACT2_PROFILE" = "true" ] ; then JAVA_COMPACT_PROFILE="compact2" ; fi
    IS_COMPACT3_PROFILE=`echo $JAVA_VERSION_OUTPUT | sed -e 's/^.*compact3.*$/true/g'`
    if [ "$IS_COMPACT3_PROFILE" = "true" ] ; then JAVA_COMPACT_PROFILE="compact3" ; fi
    echo "JAVA_COMPACT_PROFILE=$JAVA_COMPACT_PROFILE"

    IS_AZUL_JAVASE=`echo $JAVA_VERSION_OUTPUT | sed -e 's/^.*Zulu-Embedded.*$/true/g'`
    if [ "$IS_AZUL_JAVASE" = "true" ] ; then JAVA_VENDOR="Azul" ; fi
    echo "JAVA_VENDOR=$JAVA_VENDOR"
}

checkJvmVersion() {
    # Minimal requirement: Java8 with compact2 profile
    if [ "$JAVA_VERSION" -lt "80" ]; then
        echo "ERROR: JVM must be greater than 1.7"
        exit 2;
    fi
    if [ "$JAVA_COMPACT_PROFILE" != "fulljre" ]; then
        echo "ERROR: JVM must be at least Full-JRE up to now"
        exit 3;
    fi
}

# arg 0: debug enabled: true/false
setFlightRecorderOptions() {
    # in debug mode set Java Flight Recorder (JFR) options when running on Oracle JavaSE
    JFR_OPTS=""
    if [ "$1" = "true" ] ; then
        if [ "$JAVA_VENDOR" = "Oracle" ] ; then
            # use JFR when $JAVA_HOME/lib/jfr.jar is present (for Full-JRE or customized compact3 profile)
            # see also https://blogs.oracle.com/jtc/entry/using_java_fligt_recorder_with
            # in case of JAVA_HOME not set, but fulljre, enable JFR too
            if [ -f $JAVA_HOME/lib/jfr.jar -o "$JAVA_COMPACT_PROFILE" = "fulljre" ] ; then
                 # JFR there, so set JFR_OPTS
                 JFR_OPTS="$JFR_OPTS -XX:+UnlockCommercialFeatures -XX:+FlightRecorder"
                 # by default, start recording for 5 min, put to userdata folder
                 JFR_OPTS="$JFR_OPTS -XX:StartFlightRecording=duration=300s,filename=$BASE_FOLDER/userdata/smarthome-concierge.jfr"
            fi
       fi
    fi
}

# arg 0: debug enabled: true/false
setJmxOptions() {
    # enable in debug mode JMX when running on compact3/fulljre
    JMX_OPTS=""
    if [ "$1" = "true" ] ; then
        if [ "$JAVA_COMPACT_PROFILE" = "compact3" -o "$JAVA_COMPACT_PROFILE" = "fulljre" ]; then
            # compact3, fulljre: enable JMX in debug mode, needed to flight recorder too
            JMX_OPTS="$JMX_OPTS -Dcom.sun.management.jmxremote.port=7091"
            JMX_OPTS="$JMX_OPTS -Dcom.sun.management.jmxremote.rmi.port=7091"
            JMX_OPTS="$JMX_OPTS -Dcom.sun.management.jmxremote.authenticate=false"
            JMX_OPTS="$JMX_OPTS -Dcom.sun.management.jmxremote.ssl=false"
        fi
    fi
}

# arg 0: debug enabled: true/false
setDebugOptions() {
    JAVA_DEBUG_OPTS=""
    if [ "$1" = "true" ] ; then
        if [ "$JAVA_VENDOR" = "Azul" -a "$JAVA_COMPACT_PROFILE" = "compact2" ] ; then
            # will NOT be supported, $JAVA_HOME/lib/libjdwp.so is missing
            :
        else
            DEFAULT_JAVA_DEBUG_PORT="5005"
            if [ "x$JAVA_DEBUG_PORT" = "x" ]; then
                JAVA_DEBUG_PORT="$DEFAULT_JAVA_DEBUG_PORT"
            fi
            DEFAULT_JAVA_DEBUG_OPTS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=$JAVA_DEBUG_PORT"
            JAVA_DEBUG_OPTS="$JAVA_DEBUG_OPTS $DEFAULT_JAVA_DEBUG_OPTS"
        fi

        # chatty logging setttings
        JAVA_DEBUG_OPTS="$JAVA_DEBUG_OPTS -Dlogback.configurationFile=$RUNTIME_FOLDER/etc/logback_debug.xml"
    else
        # more silent logging setttings
        JAVA_DEBUG_OPTS="$JAVA_DEBUG_OPTS -Dlogback.configurationFile=$RUNTIME_FOLDER/etc/logback.xml"
    fi
}

run() {
    DEBUG_ENABLED=false
    while [ "$1" != "" ]; do
        case $1 in
            'debug')
                DEBUG_ENABLED=true
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    findJvmVersion $DEBUG_ENABLED
    checkJvmVersion

    setDebugOptions $DEBUG_ENABLED
    setFlightRecorderOptions $DEBUG_ENABLED
    setJmxOptions $DEBUG_ENABLED

    # Find the concierge framework jar
    MAIN=$(find framework -name "org.eclipse.concierge-5.0.0*.jar" | sort | tail -1);

    # show java command when debug enabled
    if [ "$DEBUG_ENABLED" = "true" ] ; then
        # echo "JAVA_OPTS=$JAVA_OPTS"
        # echo "JAVA_DEBUG_OPTS=$JAVA_DEBUG_OPTS"
        # echo "JFR_OPTS=$JFR_OPTS"
        # echo "JMX_OPTS=$JMX_OPTS"
        set -x
    fi

    $JAVA_BIN $JAVA_OPTS $JAVA_DEBUG_OPTS $JFR_OPTS $JMX_OPTS \
	    -Djava.awt.headless=true \
	    -Djava.library.path=lib \
	    -Dfile.encoding="UTF-8" \
	    -Dosgi.noShutdown=true \
	    -Dorg.osgi.framework.storage="$BASE_FOLDER/userdata/storage" \
	    -Dorg.osgi.service.http.port=$HTTP_PORT \
	    -Dorg.osgi.service.http.port.secure=$HTTPS_PORT \
	    -Declipse.ignoreApp=true \
	    -Djetty.home="$RUNTIME_FOLDER"/ \
	    -Djetty.etc.config.urls=etc/jetty.xml,etc/jetty-deployer.xml,etc/jetty-selector.xml \
	    -Dsmarthome.servicepid=org.eclipse \
	    -Dsmarthome.userdata="$BASE_FOLDER/userdata" \
	    -Dsmarthome.logdir="$BASE_FOLDER/userdata/logs" \
	    -Dsmarthome.servicecfg="$RUNTIME_FOLDER/etc/services.cfg" \
	    -Dsmarthome.configdir="$BASE_FOLDER/conf" \
	    -Dorg.quartz.properties="$RUNTIME_FOLDER/etc/quartz.properties" \
	    -Dfelix.fileinstall.dir="$BASE_FOLDER/addons" \
	    -Dfelix.fileinstall.active.level=4 \
	    -DmdnsName=smarthome \
	    -jar $MAIN "$DIRNAME/smarthome.xargs" "$@"
}

main() {
    run "$@"
}

main "$@"