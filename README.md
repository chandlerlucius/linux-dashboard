<p align="center">
  <a href="linuxdashboard.com"><img alt="Linux Dashboard" width="30%" src="https://github.com/chandlerlucius/linux-dashboard/blob/master/src/main/resources/com/utils/dashboard/img/logo-dark.svg"/></a>
</p>

<p align="center">
    <strong>Simple Bash scripting project to generate linux server
    analytics with a Java Websocket wrapper</strong>
</p>

# Linux Dashboard

[![Travis CI Build Status](https://img.shields.io/travis/chandlerlucius/linux-dashboard/master.svg?label=travis%20build)](https://travis-ci.org/chandlerlucius/linux-dashboard)
[![Latest release](https://img.shields.io/github/release/chandlerlucius/linux-dashboard.svg)](https://github.com/chandlerlucius/linux-dashboard/releases/latest)
[![Github All Releases](https://img.shields.io/github/downloads/chandlerlucius/linux-dashboard/total.svg)](https://github.com/chandlerlucius/linux-dashboard/releases/latest)
[![Gitter](https://badges.gitter.im/chandlerlucius/linux-dashboard.svg)](https://gitter.im/chandlerlucius/linux-dashboard?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

[![License](https://img.shields.io/github/license/chandlerlucius/linux-dashboard.svg)](https://github.com/chandlerlucius/linux-dashboard/blob/master/LICENSE.md)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fchandlerlucius%2Flinux-dashboard.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fchandlerlucius%2Flinux-dashboard?ref=badge_shield)

## Code

[![Coverage Status](https://coveralls.io/repos/github/chandlerlucius/linux-dashboard/badge.svg)](https://coveralls.io/github/chandlerlucius/linux-dashboard)

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/c25d8a8f98ee4993a15a6f23ecf88b37)](https://www.codacy.com/app/chandlerlucius/linux-dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=chandlerlucius/linux-dashboard&amp;utm_campaign=Badge_Grade)
[![Maintainability](https://api.codeclimate.com/v1/badges/378bdce4de9f2a85da7d/maintainability)](https://codeclimate.com/github/chandlerlucius/linux-dashboard/maintainability)
[![Maintainability Rating](https://sonarcloud.io/api/project_badges/measure?project=com.utils%3Alinux-dashboard&metric=sqale_rating)](https://sonarcloud.io/dashboard?id=com.utils%3Alinux-dashboard)

[![Reliability Rating](https://sonarcloud.io/api/project_badges/measure?project=com.utils%3Alinux-dashboard&metric=reliability_rating)](https://sonarcloud.io/dashboard?id=com.utils%3Alinux-dashboard)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=com.utils%3Alinux-dashboard&metric=security_rating)](https://sonarcloud.io/dashboard?id=com.utils%3Alinux-dashboard)
[![Vulnerabilities](https://sonarcloud.io/api/project_badges/measure?project=com.utils%3Alinux-dashboard&metric=vulnerabilities)](https://sonarcloud.io/dashboard?id=com.utils%3Alinux-dashboard)
[![Bugs](https://sonarcloud.io/api/project_badges/measure?project=com.utils%3Alinux-dashboard&metric=bugs)](https://sonarcloud.io/dashboard?id=com.utils%3Alinux-dashboard)
[![Code Smells](https://sonarcloud.io/api/project_badges/measure?project=com.utils%3Alinux-dashboard&metric=code_smells)](https://sonarcloud.io/dashboard?id=com.utils%3Alinux-dashboard)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=com.utils%3Alinux-dashboard&metric=alert_status)](https://sonarcloud.io/dashboard?id=com.utils%3Alinux-dashboard)

--Work In Progress--

This is bash script written to get basic server
analytic data and put it in a json format.

It is encased in a Java wrapper using websockets
to provide the html with constantly updating data.

Once downloaded and extracted it can be run like so:
./mvnw clean install -DskipTests;
java -jar target/linux-dashboard-0.0.1-SNAPSHOT.jar

The most recent jar is also supplied if you just want to run it:
java -jar target/linux-dashboard-0.0.1-SNAPSHOT.jar

This project is also in a plug-and-play fashion.
Meaning you can port it to your existing project by doing the following:

1. Copy all file from src/main/resources/static into your resources directory
2. Copy src/main/java/com/utils/dashboard/DashboardWebSocket.java
(Handles exposing the /websocket endpoint and the web socket code)

Tech Stack:

* Bash
* Javascript
* Java
* HTML5
* CSS3

Frameworks:

* Spring / Spring Boot (Embedded tomcat for fast deployment)
* Java WebSocket API (Constant server -> client push for continuous results)
* Materialize (Responsive web design framework)

Live Example:
www.linuxdashboard.com

## Support

For help, please use the [chat room](https://gitter.im/chandlerlucius/linux-dashboard).

## License

[MIT](LICENSE)

[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fchandlerlucius%2Flinux-dashboard.svg?type=large)](https://app.fossa.com/projects/git%2Bgithub.com%2Fchandlerlucius%2Flinux-dashboard?ref=badge_large)

## Acknowledgements
* Linting tools
  * PMD [java]
  * checkstyles [java]
  * jshint [javascript]
  * eslint [javascript]
  * shellcheck [shell]
  * htmlhint [html]
  * csslint [css]
  * stylelint [css]
  * markdownlint [markdown]
  * remarklint [markdown]
  * jsonlint [json]
  * yamllint [yaml]
* Online Tools
  * TravisCI [continuous integration / deployment]
  * SonarCloud [code quality]
  * Codacy [code quality]
  * CodeCov [code coverage]
* Testing tools
  * JUnit 5 [java]
  * Jest [javascript]
  * BATS [shell]
* Github integrations
  * FOSSA [license checker]
  * GitGuardian [credential leak detector]
  * Whitesource Bolt [vunerability finder]
