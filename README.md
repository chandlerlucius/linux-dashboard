# linux-dashboard

[![Latest release](https://img.shields.io/github/release/chandlerlucius/linux-dashboard.svg)](https://github.com/chandlerlucius/linux-dashboard/releases/latest)
[![License](https://img.shields.io/github/license/chandlerlucius/linux-dashboard.svg)](https://github.com/chandlerlucius/linux-dashboard/blob/master/LICENSE.md)
[![Travis CI Build Status](https://img.shields.io/travis/chandlerlucius/linux-dashboard/master.svg?label=travis%20build)](https://travis-ci.org/chandlerlucius/linux-dashboard)

--Work In Progress--

Bash scripting project to generate linux server analytics with a Java Websocket wrapper

This is bash script written to get basic server analytic data and put it in a json format.

It is encased in a Java wrapper using websockets to provide the html with constantly updating data.

Once downloaded and extracted it can be run like so:  
./mvnw clean install -DskipTests; java -jar target/linux-dashboard-0.0.1-SNAPSHOT.jar

The most recent jar is also supplied if you just want to run it:  
java -jar target/linux-dashboard-0.0.1-SNAPSHOT.jar

This project is also in a plug-and-play fashion. Meaning you can port it to your existing project by doing the following:
1. Copy all file from src/main/resources/static into your resources directory 
2. Copy src/main/java/com/utils/dashboard/DashboardWebSocket.java (Handles exposing the /websocket endpoint and the web socket code) into your project
3. Copy src/main/java/com/utils/dashboard/DashboardServlet.java (Handles exposing the /dashboard endpoint servlet to forward the html to the browser)

Tech Stack:
* Bash
* Javascript
* Java
* HTML5
* CSS3

Frameworks:
* Spring / Spring Boot (Embedded tomcat for fast deployment)
* Java WebSocket API (Constant server -> client pushing for continuous results)
* Materialize (Responsive web design framework)

Live Example:  
www.linuxdashboard.com
