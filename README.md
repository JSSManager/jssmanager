# Jamf Pro Manager

Jamf Pro Manager automates the installation and management of Jamf's manual installer in a multi-context (also known as multi-tenancy) environment.

A multi-context environment will allow you to host multiple Jamf Pro contexts from a single server, like so:

- https://my.jssserver.com:8443/production
- https://my.jssserver.com:8443/development
- https://my.jssserver.com:8443/testing

## Contents

- [Features](#features)
- [Installation](#installation)
- [Setup](#setup)
  - [Java](#java)
  - [MySQL](#mysql)
  - [Tomcat](#tomcat)
  - [JSS Webapp](#jss-webapp)
  - [unzip binary](#unzip binary)
  - [Environment](#environment)
- [Use](#use) 


## Features

Jamf Pro Manager can handle the following tasks.

- Deploy a new Jamf Pro context
- Upgrade an existing Jamf Pro context
- Upgrade all Jamf Pro contexts
- Delete an existing Jamf Pro context
- Display the name of all Jamf Pro contexts
- Restart Tomcat
- Start Tomcat
- Stop Tomcat

## Installation

Copy the jssmanager.sh to your desired location on your Jamf Pro server. If you are operating in a multi-server configuration, jssmanager.sh will have to be copied to every server running Tomcat, and each task must be run from each server.

## Setup

You will need to meet the following pre-requisites before Jamf Pro Manager can run sucessfully.

### Java

The Java JDK (Java Development Kit) will need to be installed. For more information on installing Java, please see https://www.jamf.com/jamf-nation/articles/667/installing-java-and-mysql-for-jamf-pro-10-14-0-or-later.

### MySQL

MySQL will need to be installed.

If operating in a single machine configuration, you will need to install MySQL server.

If operating in a configuration where your database sever is separate from your webapp server, MySQL client will need to be installed on each server running Jamf Pro Manager.

For more information on installing MySQL, please see https://www.jamf.com/jamf-nation/articles/667/installing-java-and-mysql-for-jamf-pro-10-14-0-or-later

### Tomcat

Tomcat will need to be installed. This can either be done via manual installation, or by using the Jamf Pro Installer for Linux to create your first concept. Jamf Pro Manager will auto-detect which installation method was used and act accordingly.

### Jamf Pro Webapp

You will need to place the Jamf Pro Webapp (ROOT.war) somewhere on your server. This can be found by logging into Jamf Nation, going to My Assets, and finding the Jamf Pro Manuall Installer under Show alternative downloads.

### unzip binary

The "unzip" binary must be installed on the host running jssmanager. unzip is used to extract the ROOT.war webapp into Tomcat's "webapps" folder. 

### Environment

There are several variables in the script that need to be customized to suit your environment. 

dbHost - set this to the DNS name or IP of your MySQL server. If you're running MySQL on the same server as your webapp, you can leave this set to localhost, otherwise you will need to modify it.

dbRoot - the MySQL root user.

dbDumpPath - the path where database backups should be stored.

mysqlRootPwd - The MySQL root password. Leave this blank to be prompted each time.

webapp - set this to the location or your ROOT.war file. 

logPath - where you want to store logs for the JSS. The default location is /var/log/jss.

minimumPoolSize and maximumPoolSize - settings for minimum and maximum pool size. 

## Use

Coming soon.
