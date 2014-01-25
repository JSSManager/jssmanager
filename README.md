jssmanager
==========
The purpose of this script is to automate the installation and management of JAMF's manual installer in a multi-context (also known as multi-tenancy) environment.

The script is tested using the latest version of the JSS, Ubuntu Server 12.04, Tomcat 7, and MySQL 5.5. Use in other environments at your own risk, and please test this script before using it in your production environments.

The script has the following options:

1) Deploy a new context
2) Upgrade an existing context
3) Delete an existing context

It will also restart Tomcat and create databases if needed.

Setup

The script requires a few things to be in place to operate correctly.

-Tomcat 7 should be installed on your server.

-MySQL should be installed on your database server.

-A copy of the JSS ROOT.war needs to be stored locally on the server. By default, the script will look for it in /usr/local/jssmanager, however this is stored in a variable and can be changed if needed.

-The script can be stored wherever you'd like. It does not need to be in the same location as your ROOT.war file

-This script must be run as root.

User Definable Variables - you shoud edit these to suit your environment

dbHost - set this to the DNS name or IP of your MySQL server. If you're running MySQL on the same server, you can leave this set to localhost.

dbRoot - the MySQL root user.

mysqlRootPwd - The MySQL root password. Leave this blank to be prompted eah time.

webapp - set this to the location or your ROOT.war file. The default location is recommended.

logPath - where you want to store logs for the JSS. The default location is /var/log/jss.

eth - The local ethernet interface. This is used when granting permissions on the database.
