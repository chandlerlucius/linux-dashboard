# server-analytics

--Work In Progress--

Bash scripting project to generate linux server analytics with a Java Websocket wrapper

This is bash script written to get basic server analytic data and put it in a json format.

It is encased in a Java wrapper using websockets to provide the html with constantly updating data.

Once downloaded and extracted it can be run like so:
mvn clean install -DskipTests; java -jar target/dashboard-0.0.1-SNAPSHOT.jar

The jar is also supplied if you just want to run it in: java -jar target/dashboard-0.0.1-SNAPSHOT.jar
