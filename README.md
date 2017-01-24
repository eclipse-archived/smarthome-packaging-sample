# Eclipse SmartHome Packaging Sample
<img src="https://www.eclipse.org/concierge/images/logo.png" alt="concierge osgi" width="200"/>

This repo contains a sample of how to create a small working runtime package that uses the Eclipse SmartHome framework.
You can use this example to build an own minimal distribution with a very optimized memory footprint.

More information about concierge: https://www.eclipse.org/concierge/index.php

1. Prerequisites - Install Maven
================
Please use the instructions on main project's readme to install maven: https://github.com/eclipse/smarthome#1-prerequisites
* Make sure **mvn** command is available on your path.
* Make sure you're using a **JDK 8**.

2. Checkout
================
Checkout the source code from GitHub, e.g. by running:

```
git clone https://github.com/eclipse/smarthome-packaging-sample.git
```

3. Build the distribution
================
Run
```
mvn clean install
```

The maven build will create an ZIP file with all required components like
* the concierge runtime
* Eclipse SmartHome bundles
* 3rd party bundles
* start scripts

You can find the created distribution under **/target/smarthome-packaging-sample-[version].zip**

### The directory structure of the distribution
* **addons**: Folder for hotdeployment of bundles
* **runtime**: Contains the runtime
 * **concierge**: Contains the conciege osgi runtime
    * **bundles**: Additional concierge bundles
    * **framework**: The Framework
    * **system**: Contains commons and 3rd party bundles
      * **org.eclipse.jetty**: All jetty bundles
      * **org.eclipse.smarthome**: All SmartHome bundles
 * **etc**: Quartz configuration, Jetty configuration, keystore
* **userdata**: This folder is created during the first startup and contains persistent userdata and the osgi storage.

4. Start runtime
================

The minimum requirement for running this distribution is:

* JavaSE 8, JavaSE Embedded 8, or Azul Zulu-Embedded 8
* When running embedded profiles: at least compact 2 profile


Extract the distribution zip file and start the runtime:
```
unzip smarthome-packaging-sample-[version].zip
./start.sh
```

If you are developing, you can start the distribution with

```
./start_debug.sh
```

which will
* enable debugger on port 5005
* enable JMX (at least when running on JavaSE compact 3 profile)
* enable Java Flight Recorder (JFR) when running on Oracle JVM and JFR is installed in JVM
* provide extended logging output for diagnostic purposes

5. Using the UI
================
The distribution already includes the PaperUI. 
Goto: **http://your-host:8080/** you will be redirected to **/ui/index.html**

Also included is the Apache Felix Web Console. The Apache Felix Web Console is a simple tool to inspect and manage OSGi framework
Goto: **http://your-host:8080/system/console/**

Customize the distribution
================
## Concierge configuration with XARGS file
The .xargs file can contain both runtime properties for configuring the framework, as well as a set of framework commands. Properties are declared as `-Dkey=value`. The following commands are allowed:

* `-install <bundle URL> `: installs a bundle from a given bundle URL
* `-start <bundle URL> `: starts a bundle that was previously installed from the given bundle URL
* `-istart <bundle URL> `: install and starts a bundle from a given bundle URL
* `-all <file directory> `: install and start all .jar files in a given directory
* `-initlevel <level> `: sets the startlevel that will be used for all next bundles to be installed
* `-skip `: skips the remainder of the .xargs file (handy for debugging)

See for more details: https://www.eclipse.org/concierge/documentation.php#basic

## How to add further bundles?
1. Add your bundle as dependecy in the pom.xml. For example:
```
  <!-- Eclipse SmartHome dependencies - Bindings -->
        <dependency>
            <groupId>org.eclipse.smarthome.binding</groupId>
            <artifactId>org.eclipse.smarthome.binding.wemo</artifactId>
            <version>${esh.version}</version>
        </dependency>
```
2. Add the install and startup command to XARGS file. For example:
```
# Eclipse SmartHome Bindings. Start all bindings here
-istart ${esh.dir}/org.eclipse.smarthome.binding.wemo-${esh.version}*.jar
```

The bundle couldn't be started? Please check the following conditions:
 * Is the JAR file included in the assembled ZIP? Check the /src/assemble/concierge.xml which defines the included file sets of the assembly.
 * Maybe the required import-packages are not satisfied. Add another bundle which exports the required packages.

## Change the OSGi Shell
The sample does already include two versions of osgi shell implementations:
 * Concierge Shell (default)
 * Apache Felix GoGo
 
If you want using Apache Felix GoGo simple uncomment the GoGo bundles and remove startup of concierge shell 
like:
```
# -istart ${concierge.dir}/org.eclipse.concierge.shell-${concierge.version}*.jar
-istart ${system.dir}/org.apache.felix.gogo.runtime-0.*.jar
-istart ${system.dir}/org.apache.felix.gogo.command-0.*.jar
-istart ${system.dir}/org.apache.felix.gogo.shell-0.*.jar
```

At next startup you will see the **g!** prompt instead of **concierge>**

## Passing own options to JVM
You can use `JAVA_OPTS` for passing own parameter to JVM e.g. the Java Heap size etc.

Limitations
================

* It's not possible to run XText under concierge due to dependencies on equinox runtime. 
For this reason all modeling packages have been removed from this distribution. 
There are no .items, .rule, .thing, etc. files. Try to use new generation rule engine to manage rules.
* The current distribution does not run on JavaSE compact 2/3 profiles, as
  * logback-1.1.7 requires at least compact 3
  * org.eclipse.smarthome.core.scheduler requires quartz, which requires Full-JRE
  * Same for org.eclipse.smarthome.automation.scheduler
  * The packaged Jersey-min implementation requires JAXB, which requires Full-JRE

