# JSS Manager

JSS Manager automates the installation and management of JAMF's manual installer in a multi-context (also known as multi-tenancy) environment.

A multi-context environment will allow you to host multiple JSS contexts from a single server, like so:

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
  - [Environment](#environment)
- [Use](#use) 


## Features

JSS Manager can handle the following tasks.

- Deploy a new JSS context
- Upgrade an existing JSS context
- Upgrade all JSS contexts
- Delete an existing JSS context
- Display the name of all JSS contexts
- Restart Tomcat
- Start Tomcat
- Stop Tomcat

## Installation

Copy the jssmanager.sh to your desired location on your JSS server. If you are operating in a multi-server configuration, jssmanager.sh will have to be copied to every server running Tomcat, and each task must be run from each server.

## Setup

You will need to meet the following pre-requisites before JSS Manager can run sucessfully.

### Java

The Java JDK (Java Development Kit) will need to be installed. For more information on installing Java, please see https://jamfnation.jamfsoftware.com/article.html?id=28.

### MySQL

MySQL will need to be installed.

If operating in a single machine configuration, you will need to install MySQL server.

If operating in a configuration where your database sever is separate from your webapp server, MySQL client will need to be installed on each server running JSS Manager.

For more information on installing MySQL, please see https://jamfnation.jamfsoftware.com/article.html?id=28.

### Tomcat

Tomcat will need to be installed. This can either be done via manual installation, or using JAMF Software's JSS Installer for Linux to create your first concept. JSS Manager will auto-detect which installation method was used and act accordingly.

### JSS Webapp

You will need to place the JSS Webapp (ROOT.war) somewhere on your server. This can be found by logging into JAMF Nation, going to My Assets, and finding the JSS Manuall Installer under Show alternative downloads.

### Environment

There are several variables in the script that need to be customized to suit your environment. 

dbHost - set this to the DNS name or IP of your MySQL server. If you're running MySQL on the same server as your webapp, you can leave this set to localhost, otherwise you will need to modify it.

dbRoot - the MySQL root user.

mysqlRootPwd - The MySQL root password. Leave this blank to be prompted eah time.

webapp - set this to the location or your ROOT.war file. 

logPath - where you want to store logs for the JSS. The default location is /var/log/jss.

eth - The local ethernet interface. This is used when granting permissions on the database. This should not need to be changed unless you have multiple interfaces on your server AND your MySQL databases are on a separate server. Use the interface that will be used when communicating from the Tomcat server to the MySQL server.

## Use

Coming soon.
