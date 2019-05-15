<h1 align="center">
    <a href="linuxdashboard.com"><img alt="Linux Dashboard" width="30%" src="https://github.com/chandlerlucius/linux-dashboard/blob/master/src/main/resources/com/utils/dashboard/img/logo-dark.svg"/></a>
</h1>

<p align="center">
    <strong>Simple Bash scripting project to generate linux server
    analytics with a Java Websocket wrapper</strong>
</p>

<p align="center">
    <a href="https://travis-ci.org/chandlerlucius/linux-dashboard">
        <img src="https://travis-ci.org/chandlerlucius/linux-dashboard.svg" alt="Build Status">
    </a>
    <a href="https://libraries.io/github/chandlerlucius/linux-dashboard">
        <img src="https://img.shields.io/librariesio/github/chandlerlucius/linux-dashboard.svg" alt="Dependency Status" />
    </a>
    <a href="https://github.com/chandlerlucius/linux-dashboard/releases/latest">
        <img src="https://img.shields.io/github/release/chandlerlucius/linux-dashboard.svg" alt="Latest Release" />
    </a>
    <a href="https://github.com/chandlerlucius/linux-dashboard/releases">
        <img src="https://img.shields.io/github/downloads/chandlerlucius/linux-dashboard/total.svg" alt="Releases" />
    </a>
    <a href="https://gitter.im/chandlerlucius/linux-dashboard">
        <img src="https://badges.gitter.im/chandlerlucius/linux-dashboard.svg" alt="Gitter Chat Room" />
    </a>
    <a href="https://github.com/chandlerlucius/linux-dashboard/blob/master/LICENSE">
        <img src="https://img.shields.io/github/license/chandlerlucius/linux-dashboard.svg" alt="License" />
    </a>
    <a href="https://app.fossa.com/projects/git%2Bgithub.com%2Fchandlerlucius%2Flinux-dashboard?ref=badge_shield">
        <img src="https://app.fossa.com/api/projects/git%2Bgithub.com%2Fchandlerlucius%2Flinux-dashboard.svg?type=shield" alt="FOSSA Status" />
    </a>
</p>

<p align="center">
    <a href="https://codecov.io/gh/chandlerlucius/linux-dashboard">
        <img src="https://codecov.io/gh/chandlerlucius/linux-dashboard/branch/master/graph/badge.svg" alt="Code Coverage" />
    </a>
    <a href="https://www.codacy.com/app/chandlerlucius/linux-dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=chandlerlucius/linux-dashboard&amp;utm_campaign=Badge_Grade">
        <img src="https://api.codacy.com/project/badge/Grade/c25d8a8f98ee4993a15a6f23ecf88b37" alt="Code Quality" />
    </a>
    <a href="https://sonarcloud.io/dashboard?id=com.utils%3Alinux-dashboard">
        <img src="https://sonarcloud.io/api/project_badges/measure?project=com.utils%3Alinux-dashboard&metric=alert_status" alt="Quality Gate" />
    </a>
    <a href="https://sonarcloud.io/dashboard?id=com.utils%3Alinux-dashboard">
        <img src="https://sonarcloud.io/api/project_badges/measure?project=com.utils%3Alinux-dashboard&metric=sqale_rating" alt="Maintainability Rating" />
    </a>
    <a href="https://sonarcloud.io/dashboard?id=com.utils%3Alinux-dashboard">
        <img src="https://sonarcloud.io/api/project_badges/measure?project=com.utils%3Alinux-dashboard&metric=reliability_rating" alt="Reliability Rating" />
    </a>
    <a href="https://sonarcloud.io/dashboard?id=com.utils%3Alinux-dashboard">
        <img src="https://sonarcloud.io/api/project_badges/measure?project=com.utils%3Alinux-dashboard&metric=security_rating" alt="Security Rating" />
    </a>
</p>

# Linux Dashboard

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

* [Spring / Spring Boot]() - Embedded tomcat for fast deployment
* [Java WebSocket API]() - Constant server -> client push for continuous results
* [Materialize]() - Responsive web design framework

Live Example:
www.linuxdashboard.com

## Support

For help, please use the [chat room](https://gitter.im/chandlerlucius/linux-dashboard).

## License

[MIT](LICENSE)

[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fchandlerlucius%2Flinux-dashboard.svg?type=large)](https://app.fossa.com/projects/git%2Bgithub.com%2Fchandlerlucius%2Flinux-dashboard?ref=badge_large)

## Acknowledgements

<table>
<caption>Linting Tools</caption>
<thead>
    <tr>
        <th>Logo/Link</th>
        <th>Name</th>
        <th>Language</th>
        <th>Source</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td>
            <a href="https://pmd.github.io" target="_blank" rel="noopener noreferrer">
                <img src="https://pmd.github.io/img/pmd_logo.png" alt="PMD" height="30px"/>
            </a>
        </td>
        <td>PMD</td>
        <td>java</td>
        <td>
            <a href="https://github.com/pmd/pmd" target="_blank" rel="noopener noreferrer">https://github.com/pmd/pmd</a>
        </td>
    </tr>
    <tr>
        <td>
            <a href="https://spotbugs.github.io" target="_blank" rel="noopener noreferrer">
                <img src="https://spotbugs.github.io/images/logos/spotbugs_icon_only_zoom_256px.png" alt="Spotbugs" height="30px"/>
            </a>
        </td>
        <td>Spotbugs</td>
        <td>java</td>
        <td>
            <a href="https://github.com/spotbugs/spotbugs" target="_blank" rel="noopener noreferrer">https://github.com/spotbugs/spotbugs</a>
        </td>
    </tr>
    <tr>
        <td>
            <a href="http://checkstyle.sourceforge.net/" target="_blank" rel="noopener noreferrer">
                <img src="http://checkstyle.sourceforge.net/images/header-checkstyle-logo.png" alt="Checkstyle" height="30px"/>
            </a>
        </td>
        <td>Checkstyle</td>
        <td>java</td>
        <td>
            <a href="https://github.com/checkstyle/checkstyle" target="_blank" rel="noopener noreferrer">https://github.com/checkstyle/checkstyle</a>
        </td>
    </tr>
    <tr>
        <td>
            <a href="https://jshint.com/" target="_blank" rel="noopener noreferrer">
                <img src="https://jshint.com/res/jshint-dark.png" alt="JSHint" height="30px"/>
            </a>
        </td>
        <td>JSHint</td>
        <td>javascript</td>
        <td>
            <a href="https://github.com/jshint/jshint" target="_blank" rel="noopener noreferrer">https://github.com/jshint/jshint</a>
        </td>
    </tr>
</tbody>
</table>

* Linting tools
  * [PMD]() - java
  * [spotbugs]() - java
  * [checkstyles]() - java
  * [jshint]() - javascript
  * [eslint]() - javascript
  * [csslint]() - css
  * [stylelint]() - css
  * [markdownlint]() - markdown
  * [remarklint]() - markdown
  * [shellcheck]() - shell
  * [htmlhint]() - html
  * [jsonlint]() - json
  * [yamllint]() - yaml
* Online Tools
  * [TravisCI]() - continuous integration / deployment
  * [SonarCloud]() - code quality
  * [Codacy]() - code quality
  * [CodeCov]() - code coverage
* Testing tools
  * [JUnit 5]() - java
  * [Jest]() - javascript
  * [BATS]() - shell
* Github integrations
  * [FOSSA]() - license checker
  * [Libraries.io]() - depedency scanner
  * [GitGuardian]() - credential leak detector
  * [Whitesource Bolt]() - vunerability finder
