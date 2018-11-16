# Eclipse SmartHome Packaging Sample - Logging Options

## Overview

Eclipse SmartHome is using [slf4j API](https://www.slf4j.org/) as the common logging API. Based on slf4j architecture different logging backends can be used just by changing deployment and configuration.

This packaging sample is using the `java.util.logging` backend by default. The following documentation describes what needs to be done to use either `java.util.logging` (JUL) or [logback](https://logback.qos.ch) as logging backend.

## Use java.util.logging backend

* Change `runtime/concierge/start.sh` to set `JAVA_DEBUG_OPTS` to JUL configuration
  * `logging_debug.properties` for debugging enabled
  * `logging.properties` for no debugging enabled
* Add these files to runtime distribution. You can use the [Eclipse SmartHome files](https://github.com/eclipse/smarthome-packaging-sample/blob/master/distro/runtime/etc/logging_debug.properties) as base for it

```
JAVA_DEBUG_OPTS="$JAVA_DEBUG_OPTS -Djava.util.logging.config.file=$RUNTIME_FOLDER/etc/logging_debug.properties"
```

* Change `runtime/concierge/smarthome.xargs`file to include the required bundles
  * Use `slf4j-jdk14-<version>.jar` as bridge from slf4j to JUL backend
  * do NOT include the jul-to-slf4j bridge as it would result in an [endless loop](https://www.slf4j.org/legacy.html#julRecursion)

```
# Enable logging
-install ${system.dir}/slf4j-api-1.7*.jar
-install ${system.dir}/slf4j-jdk14-1.7*.jar
-start ${system.dir}/slf4j-api-1.7*.jar
# Install bridges for JCL, OSGi and log4j
-istart ${system.dir}/jcl-over-slf4j-1.7*.jar
-istart ${system.dir}/osgi-over-slf4j-1.7*.jar
-istart ${system.dir}/log4j-over-slf4j-1.7*.jar
```

* add required files (`slf4j-jdk14-<version>.jar`, `logging*.properties`) to distribution in `src/assemble/concierge.xml` and `pom.xml`

With `java.util.logging` there is no easy way to use multiple files for different logging output, e.g. put events in its own logfiles.
If you want to do that you have to provide a second FileHandler and configure that accordingly.
For details see http://stackoverflow.com/questions/8248899/java-logging-how-to-redirect-output-to-a-custom-log-file-for-a-logger


## Use logback backend

* Change `runtime/concierge/start.sh` to set `JAVA_DEBUG_OPTS` to logback configuration
  * `logback_debug.xml` for debugging enabled
  * `logback.xml` for no debugging enabled
* Add these files to runtime distribution. You can use the [Eclipse SmartHome files](https://github.com/eclipse/smarthome/blob/master/distribution/smarthome/logback_debug.xml) as base for it

```
JAVA_DEBUG_OPTS="$JAVA_DEBUG_OPTS -Dlogback.configurationFile=$RUNTIME_FOLDER/etc/logback_debug.xml"
```

* Change `runtime/concierge/smarthome.xargs`file to include the required logback bundles
  * Use `logback-core-<version>.jar`, `logback-classic-<version>.jar` as bridge from slf4j to logback backend
  * include the jul-to-slf4j bridge to forward java.util.logging to slf4j

```
# Enable logging
-install ${system.dir}/slf4j-api-1.7*.jar
-install ${system.dir}/logback-core-1.1.7*.jar
-install ${system.dir}/logback-classic-1.1.7*.jar
-start ${system.dir}/logback-core-1.1.7*.jar
-start ${system.dir}/logback-classic-1.1.7*.jar
-start ${system.dir}/slf4j-api-1.7*.jar
# Install bridges for JCL, JUL, OSGi and log4j
-istart ${system.dir}/jcl-over-slf4j-1.7*.jar
-istart ${system.dir}/jul-to-slf4j-1.7*.jar
-istart ${system.dir}/osgi-over-slf4j-1.7*.jar
-istart ${system.dir}/log4j-over-slf4j-1.7*.jar
```

* add required files (`logback-core-<version>.jar`, `logback-classic-<version>.jar`, `logback*.xml`) to distribution in `src/assemble/concierge.xml` and `pom.xml`
