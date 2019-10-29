#!/bin/bash
#
##########################################################################################
#
#	Jamf Pro Manager
#
#	This program is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; either version 2 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License along
#	with this program; if not, write to the Free Software Foundation, Inc.,
#	51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
##########################################################################################
#
#	ABOUT THIS PROGRAM
#
#	NAME
#	Jamf Pro Manager
#
#	DOCUMENTATION
#	See https://github.com/JSSManager/jssmanager for documentation and information
#
##########################################################################################


##########################################################################################
############### Edit the following variables to suit your environment ####################
##########################################################################################

# The FQDN or IP of your MySQL database host
# Leave this blank to have the script prompt each time
dbHost="localhost"

# MySQL root user
dbRoot="root"

# MySQL root password
# Leave this blank to have the script prompt each time
mysqlRootPwd=""

# Path to dump MySQL database (do not leave a trailing / at the end of your path)
dbDumpPath="/usr/local/jssmanager/backups"

# Set dbDump to "yes" to always dump the database without asking
# Set dbDump to "no" to never dump the database without asking
# Set dbDump to "prompt" to always be asked if you want to dump the database
dbDump="prompt"

# Path where you store your JSS logs (do not leave a trailing / at the end of your path)
logPath="/var/log/jss"

# Path to your .war file
webapp="/usr/local/jssmanager/ROOT.war"

# Settings for minimum and maximum pool size. The default values are 5 for minumum pool size and 45 for maximum pool size.
# However, for clustered instances, these values are too high. Use the settings below to adjust the values as needed.
minimumPoolSize="1"
maximumPoolSize="10"

# Path to the log file for the jssmanager
logLocation="/var/log/"

########### It is not recommended that you make any changes after this line ##############

##########################################################################################
################################### Begin functions ######################################
##########################################################################################

# The yesNo function is used several times throughout the script to confirm the
# user wants to continue with the operation.
yesNo()
{
echo "(y/n)"
yesNo=""
read -r yno
case "${yno}" in
	[yY] | [yY][Ee][Ss] )
		yesNo="yes"
	;;
	[nN] | [nN][Oo] )
		yesNo="no"
	;;
	*)
		echo "Invalid input."
	;;
esac
}

# The deleteMenu function prompts the user for the name of the context they want to delete
deleteMenu()
{
echo "Please enter the name of the context you would like to delete."
echo
read -r -p "Context Name: " contextName

if [ ! -d "${tomcatPath}/webapps/${contextName}" ]
then
	echo "${contextName} is not a valid Jamf Pro context."
	sleep 3
else
	echo "${contextName} will be deleted."
	echo "Would you like to continue?"
	yesNo

	if [ "${yesNo}" = "yes" ]
	then
		echo "Deleting ${contextName}..."
		deleteWebapp
	else
		echo "${contextName} will not be deleted."
	fi
fi
mainMenu
}

# The deleteWebapp function deletes the Jamf Pro webapp for the specified context.
deleteWebapp()
{
if [ -f "${tomcatPath}/webapps/${contextName}.war" ]
then
	if rm -rf "${tomcatPath}/webapps/${contextName}.war"
	then
		echo "Deleted ${tomcatPath}/webapps/${contextName}.war."
	else
		echo "Unable to delete ${tomcatPath}/webapps/${contextName}.war."
	fi
fi

if rm -rf "${tomcatPath}/webapps/${contextName}"
then
	echo "Deleted ${tomcatPath}/webapps/${contextName}."
else
	echo "Unable to delete ${tomcatPath}/webapps/${contextName}."
fi
}

# The readDatabaseSettings function reads the DataBase.xml file for the specified context and reads
# the Database host, name, user and password settings. This is used when upgrading existing Jamf Pro contexts.
readDatabaseSettings()
{
echo "Reading database connection settings..."

dbHost=""
dbName=""
dbUser=""
dbPass=""

if dbHost=$(sed -n 's|\s*<ServerName>\(.*\)</ServerName>|\1|p' "${tomcatPath}/webapps/${contextName}/WEB-INF/xml/DataBase.xml")
then
	echo "Database host is ${dbHost}"
else
	echo "Unable to retrieve database host."
fi

if dbName=$(sed -n 's|\s*<DataBaseName>\(.*\)</DataBaseName>|\1|p' "${tomcatPath}/webapps/${contextName}/WEB-INF/xml/DataBase.xml")
then
	echo "Database name is ${dbName}"
else
	echo "Unable to retrieve database name."
fi

if dbUser=$(sed -n 's|\s*<DataBaseUser>\(.*\)</DataBaseUser>|\1|p' "${tomcatPath}/webapps/${contextName}/WEB-INF/xml/DataBase.xml")
then
	echo "Database user is ${dbUser}"
else
	echo "Unable to retrieve database user."
fi

if dbPass=$(sed -n 's|\s*<DataBasePassword>\(.*\)</DataBasePassword>|\1|p' "${tomcatPath}/webapps/${contextName}/WEB-INF/xml/DataBase.xml")
then
	echo "Database password is ${dbPass}"
else
	echo "Unable to retrieve database password."
fi

if [ -z "${dbHost}" ] || [ -z "${dbName}" ] || [ -z "${dbUser}" ] || [ -z "${dbPass}" ]
then
	echo
	echo "Unable to retrieve database settings."
	echo "The updated webapp will be unable to connect to the database."
	echo "Do you want to continue?"
	yesNo
	if [ "${yesNo}" = "yes" ]
	then
		echo "Continuing update without database connection information."
	else
		mainMenu
	fi
fi
}

# The touchLogFiles function first checks for the existance of the directory specified in logPath
# and gives the option to create or specify a new path if it doesn't exist. It then checks for the
# existance of unique log files for the context, and creates them if none are found.
touchLogFiles()
{
until [ -d "${logPath}" ]
do
	echo "${logPath} does not exist."
	echo "Would you like to create it?"
	yesNo

	if [ "${yesNo}" = "yes" ]
	then
		echo "Creating ${logPath}..."
		if mkdir -p "${logPath}"
		then
			echo "Created ${logPath}."
		else
			echo "Unable to create ${logPath}."
		fi
	elif [ "${yesNo}" = "no" ]
	then
		echo
		echo "Please specify a new directory for log files."
		echo "Make sure not to leave a trailing / at the end of your path."
		echo
		read -r -p "Log directory: " logPath
	fi
done

if [ ! -d "${logPath}/${contextName}" ]
then
	echo "Creating ${logPath}/${contextName}/..."
	if mkdir "${logPath}/${contextName}"
	then
		echo "Created ${logPath}/${contextName}/."
	else
		echo "Error: Unable to create ${logPath}/${contextName}/."
	fi
	if ! chown jamftomcat:jamftomcat "${logPath}/${contextName}"
	then
		echo "Error: unable to change ownership on ${logPath}/${contextName}."
	fi
else
	echo "${logPath}/${contextName}/ exists."
fi

if [ ! -f "${logPath}/${contextName}/JAMFSoftwareServer.log" ]
then
	echo "Creating ${logPath}/${contextName}/JAMFSoftwareServer.log..."
	if touch "${logPath}/${contextName}/JAMFSoftwareServer.log"
	then
		echo "Created JAMFSoftwareServer.log in ${logPath}/${contextName}/."
	else
		echo "Error: Unable to create JAMFSoftwareServer.log in ${logPath}/${contextName}/."
	fi
	if ! chown jamftomcat:jamftomcat "${logPath}/${contextName}/JAMFSoftwareServer.log"
	then
		echo "Error: Unable to change ownership on JAMFSoftwareServer.log in ${logPath}/${contextName}/."
	fi
else
	echo "${logPath}/${contextName}/JAMFSoftwareServer.log exists."
fi

if [ ! -f "${logPath}/${contextName}/JAMFChangeManagement.log" ]
then
	echo "Creating ${logPath}/${contextName}/JAMFChangeManagement.log..."
	if touch "${logPath}/${contextName}/JAMFChangeManagement.log"
	then
		echo "Created JAMFChangeManagement.log in ${logPath}/${contextName}/."
	else
		echo "Error: Unable to create JAMFChangeManagement.log in ${logPath}/${contextName}/."
	fi
	if ! chown jamftomcat:jamftomcat "${logPath}/${contextName}/JAMFChangeManagement.log"
	then
		echo "Error: Unable to change ownership on JAMFChangeManagement.log in ${logPath}/${contextName}/."
	fi
else
	echo "${logPath}/${contextName}/JAMFChangeManagement.log exists."
fi

if [ ! -f "${logPath}/${contextName}/JSSAccess.log" ]
then
	echo "Creating ${logPath}/${contextName}/JSSAccess.log..."
	if touch "${logPath}/${contextName}/JSSAccess.log"
	then
		echo "Created JSSAccess.log in ${logPath}/${contextName}/."
	else
		echo "Error: Unable to create JSSAccess.log in ${logPath}/${contextName}/."
	fi
	if ! chown jamftomcat:jamftomcat "${logPath}/${contextName}/JSSAccess.log"
	then
		echo "Error: Unable to change ownership on JSSAccess.log in ${logPath}/${contextName}/."
	fi
else
	echo "${logPath}/${contextName}/JSSAccess.log exists."
fi
}

# The deployWebapp function deploys the Jamf Pro webapp using the specified context name and database connection settings.
deployWebapp()
{
echo "Deploying Tomcat webapp..."
if ! unzip "${webapp}" -d "${tomcatPath}/webapps/${contextName}" >/dev/null
then
	echo "Error: unable to unzip ${webapp} to ${tomcatPath}/webapps/."
else
	chown -R jamftomcat:jamftomcat "${tomcatPath}/webapps/${contextName}"
fi

# Sleep timer to allow tomcat app to deploy
counter=0
while [ "${counter}" -lt 12 ]
do
	if [ ! -f "${tomcatPath}/webapps/${contextName}/WEB-INF/xml/DataBase.xml" ] || [ ! -f "${tomcatPath}/webapps/${contextName}/WEB-INF/classes/log4j.properties" ]
	then
		echo "Waiting for Tomcat webapp to deploy..."
		sleep 5
		((counter++))
	else
		((counter=12))
	fi
done

if [ ! -f "${tomcatPath}/webapps/${contextName}/WEB-INF/xml/DataBase.xml" ] || [ ! -f "${tomcatPath}/webapps/${contextName}/WEB-INF/classes/log4j.properties" ]
then
	echo "Something went wrong. Tomcat webapp has not deployed."
	echo "Aborting!"
	sleep 1
	mainMenu
else
	echo "Webapp has deployed."
fi

# Change log4j files to point logs to new log locations
echo "Updating log4j files..."
if ! sed -e "s@log4j.appender.JAMFCMFILE.File=.*@log4j.appender.JAMFCMFILE.File=${logPath}/${contextName}/JAMFChangeManagement.log@" -e "s@log4j.appender.JAMF.File=.*@log4j.appender.JAMF.File=${logPath}/${contextName}/JAMFSoftwareServer.log@" -e "s@log4j.appender.JSSACCESSLOG.File=.*@log4j.appender.JSSACCESSLOG.File=${logPath}/${contextName}/JSSAccess.log@" -i "${tomcatPath}/webapps/${contextName}/WEB-INF/classes/log4j.properties"
then
	echo "Error: Unable to write settings to log4j.properties."
fi
# Add database connection info to Jamf Pro context

echo "Writing database connection settings..."
if ! sed -e "s@<ServerName>.*@<ServerName>${dbHost}</ServerName>@" -e "s@<DataBaseName>.*@<DataBaseName>${dbName}</DataBaseName>@" -e "s@<DataBaseUser>.*@<DataBaseUser>${dbUser}</DataBaseUser>@" -e "s@<DataBasePassword>.*@<DataBasePassword>${dbPass}</DataBasePassword>@" -e "s@<MinPoolSize>.*@<MinPoolSize>${minimumPoolSize}</MinPoolSize>@" -e "s@<MaxPoolSize>.*@<MaxPoolSize>${maximumPoolSize}</MaxPoolSize>@" -i "${tomcatPath}/webapps/${contextName}/WEB-INF/xml/DataBase.xml"
then
	echo "Error: Unable to write settings to DataBase.xml."
fi
}

# The updateWebapp function asks the user for the name of the context, validates it, then uses the readDatabaseSettings function
# to pull the existing database connection settings and store them, then tests the settings to ensure authentication to the database,
# then it will verify the log files exist and create them if not, then it will delete the existing webapp and deploy the new webapp.
updateWebapp()
{
echo "Please enter the name of the context you would like to update."
echo
read -r -p "Context Name: " contextName

if [ ! -d "${tomcatPath}/webapps/${contextName}" ]
then
	echo "${contextName} is not a valid Jamf Pro context."
	sleep 3
else
	echo "${contextName} will be updated."
	echo "Would you like to continue?"
	yesNo

	if [ "${yesNo}" = "yes" ]
	then
		echo "Updating ${contextName}..."
		tomcatStopPrompt
		updateContext
		tomcatStartPrompt
	else
		echo "${contextName} will not be updated."
	fi
fi
mainMenu
}

# The updateAll function will update all existing contexts in the Tomcat webapp directory.
updateAll()
{
dbDumpPrompt
echo "All existing Jamf Pro contexts will be updated."
echo "Are you sure you want to continue?"
yesNo
if [ "${yesNo}" = "yes" ]
then
	tomcatStopPrompt
	for dirs in "${tomcatPath}/webapps/"*/
	do
		contextName="$(basename "${dirs}")"
		echo
		echo "Updating ${contextName}..."
		updateContext
	done
fi
tomcatStartPrompt
mainMenu
}

# The displayAll function is used to display a list of all Jamf Pro contexts
displayAll()
{
echo "Existing Jamf Pro contexts:"
echo
for dirs in "${tomcatPath}/webapps/"*/
do
	contextName="$(basename "${dirs}")"
	echo "${contextName}"
	echo ""
done
echo
read -r -s -p "Press [Enter] to return to the main menu"
mainMenu
}

# The updateContext function is a wrapper for other functions only.
updateContext()
{
readDatabaseSettings
if [ "${dbDump}" = "yes" ]
then
	dumpDatabase
fi
touchLogFiles
deleteWebapp
deployWebapp
}

# The newContext function gets the context name and database connection information from the user, and deploys a new context.
# If the user enters an context name that is already in use, the script will prompt to upgrade the context instead.
newContext()
{
echo
echo "Please enter a name for this context."
echo
read -r -p "Context Name: " contextName

if [ -d "${tomcatPath}/webapps/${contextName}" ]
then
	echo "${contextName} already exists."
	echo "Would you like to upgrade this context?"
	yesNo
	if [ "${yesNo}" = "yes" ]
	then
		echo "Updating ${contextName}..."
		tomcatStopPrompt
		updateContext
		tomcatStartPrompt
	elif [ "${yesNo}" = "no" ]
	then
		echo "Aborting deployment."
	fi
else
	echo
	echo "Please enter the name of the database."
	echo
	read -r -p "Database Name: " dbName
	echo
	echo "Please enter the name of the database user."
	echo
	read -r -p "Database User: " dbUser
	echo
	echo "Please enter the database user's password."
	echo
	read -r -s -p "Database Password: " dbPass

	if [ "${dbHost}" = "" ]
	then
		echo "Please enter the hostname or IP address of the database server."
		echo
		read -r -p "Database Server: " dbHost
	fi

	echo "A new context will be deployed with the following settings."
	echo
	echo "Context Name: ${contextName}"
	echo "Database Name: ${dbName}"
	echo "Database User: ${dbUser}"
	echo "Database Pass: ${dbPass}"
	echo "Database Host: ${dbHost}"
	echo
	echo "Would you like to continue?"
	yesNo

	if [ "${yesNo}" = "yes" ]
	then
		tomcatStopPrompt
		testDatabase
		touchLogFiles
		deployWebapp
		tomcatStartPrompt
	elif [ "${yesNo}" = "no" ]
	then
		echo "Context will not be created."
		sleep 3
		mainMenu
	fi
fi
mainMenu
}

# The createDatabase function creates a database on the host server
createDatabase()
{
echo "Creating database ${dbName}..."
if mysql -h "${dbHost}" -u "${dbRoot}" -p"${mysqlRootPwd}" -e "CREATE DATABASE ${dbName};"
then
	echo "Database ${dbName} created."
else
	echo "Error: Unable to create database ${dbName}."
fi
}

# The grantPermissions function grants permission to a user for the specified database
grantPermissions()
{
echo "Creating user ${dbUser} at ${serverAddress}..."
if mysql -h "${dbHost}" -u "${dbRoot}" -p"${mysqlRootPwd}" -e "CREATE USER '${dbUser}'@'${serverAddress}' IDENTIFIED WITH mysql_native_password BY '${dbPass}';"
then
	echo "User created."
else
	echo "Error: Unable to create user."
fi

echo "Granting permissions on database ${dbName} to user ${dbUser} at ${serverAddress}..."
if mysql -h "${dbHost}" -u "${dbRoot}" -p"${mysqlRootPwd}" -e "GRANT ALL ON ${dbName}.* TO '${dbUser}'@'${serverAddress}';"
then
	echo "Permissions granted."
else
	echo "Error: Unable to grant permissions."
fi
}

# The testMysqlRoot function will check if the supplied credentials for MySQL root are correct.
testMysqlRoot()
{
echo "Testing MySQL root username and password..."
# The following could potentially cause an infinite loop if a successful connection
# to the database host can not be established
until mysql -h "${dbHost}" -u "${dbRoot}" -p"${mysqlRootPwd}" -e ";" ;
do
	echo "Invalid MySQL root username or password. Please retry."
	read -r -p "MySQL Root User: " dbRoot
	read -r -s -p "MySQL Root Password: " mysqlRootPwd
done
}

# The testDatabase function will first test for the existence of the database using the root credentials, then checks to see
# if the specified user has permission to access the database, offering to create the database and grant permissions as needed.
testDatabase()
{
if [ "${dbHost}" = "localhost" ]
then
	serverAddress="localhost"
else
	serverAddress=$(hostname -I)
fi

if [ -z "${mysqlRootPwd}" ]
then
	read -r -s -p "Enter MySQL root password: " mysqlRootPwd
fi

testMysqlRoot

echo
echo "Checking database connection settings..."

dbTestUser=$(mysqlshow --host="${dbHost}" --user="${dbUser}" --password="${dbPass}" "${dbName}" | grep -v Wildcard | grep -o "${dbName}")

if [ -z "${dbTestUser}" ]
then
	dbTestRoot=$(mysqlshow --host="${dbHost}" --user="${dbRoot}" --password="${mysqlRootPwd}" "${dbName}" | grep -v Wildcard | grep -o "${dbName}")
	if [ -z "${dbTestRoot}" ]
	then
		echo "Database ${dbName} does not seem to exist."
		echo "Would you like to create it?"
		yesNo
		if [ "${yesNo}" = "yes" ]
		then
			createDatabase
			grantPermissions
		elif [ "${yesNo}" = "no" ]
		then
			echo "Database will not be created."
			echo "WARNING: The Webapp may not be able to connect to the database."
		fi
	elif [ "${dbTestRoot}" = "${dbName}" ]
	then
		echo "User ${dbUser} does not seem to have permission to access database ${dbName}."
		echo "Would you like to grant permissions?"
		yesNo
		if [ "${yesNo}" = "yes" ]
		then
			grantPermissions
		elif [ "${yesNo}" = "no" ]
		then
			echo "User will not be granted permission."
			echo "WARNING: The Webapp may not be able to connect to the database."
		fi
	fi
else
	echo "Database connection test successful."
fi
}

dumpDatabase()
{
if [ -z "${mysqlRootPwd}" ]
then
	read -r -s -p "Enter MySQL root password: " mysqlRootPwd
fi

testMysqlRoot

dbTestRoot=$(mysqlshow --host="${dbHost}" --user="${dbRoot}" --password="${mysqlRootPwd}" "${dbName}" | grep -v Wildcard | grep -o "${dbName}")
if [ -z "${dbTestRoot}" ]
then
	echo "WARNING: Database ${dbName} does not appear to exist!"
else
	if [ ! -d "${dbDumpPath}/${dbName}" ]
	then
		echo "Creating ${dbDumpPath}/${dbName}..."
		if ! mkdir -p "${dbDumpPath}/${dbName}"
		then
			echo "Error: Unable to create ${dbDumpPath}/${dbName}."
			echo "Aborting!"
			sleep 1
			mainMenu
		fi
	fi

	NOW="$(date +"%Y-%m-%d-%H-%M")"
	echo "Dumping database ${dbName} to ${dbDumpPath}..."
	if mysqldump -h "${dbHost}" -u "${dbRoot}" -p"${mysqlRootPwd}" "${dbName}" > "${dbDumpPath}/${dbName}/$NOW.${dbName}.sql"
	then
		echo "Database dump successful."
	else
		echo "Error: Unable to dump the database."
		echo "Aborting!"
		mainMenu
	fi
fi
}

dbDumpPrompt()
{
if [ "${dbDump}" != "no" ] && [ "${dbDump}" != "yes" ]
then
	echo "Would you like to backup the database(s) before proceeding?"
	yesNo
	if [ "${yesNo}" = "yes" ]
	then
		dbDump="yes"
	elif [ "${yesNo}" = "no" ]
	then
		dbDump="no"
	fi
fi
}

# Check to make sure script is being run as root
checkRoot()
{
echo "Checking to see if logged in as root..."
if [ "$(id -un)" != "root" ]
then
	echo "ID10T Error: You must be root to run this script."
	sleep 1
	echo "Aborting!"
	sleep 3
	exit 1
else
	echo "Congratulations! You followed the directions and ran the script as root!"
fi
}

# Check to make sure ROOT.war exists at the specified path
checkWebapp()
{
echo "Checking for ${webapp}..."

if [ ! -f "${webapp}" ]
then
	echo "${webapp} not found!"
	sleep 1
	echo "Aborting!"
	sleep 3
	exit 1
else
	echo "Webapp found at ${webapp}."
fi
}

# Check Tomcat installation method and set appropriate Tomcat path
checkTomcat()
{
echo "Checking Tomcat installation..."
if [ -d "/usr/local/jss/tomcat" ]
then
	tomcatPath="/usr/local/jss/tomcat"
else
	echo "Tomcat does not appear to be installed."
	echo "Please install Tomcat before using this script."
	echo "Exiting..."
	sleep 3
	exit 1
fi

echo "Tomcat path is ${tomcatPath}."
}

# The tomcatStartPrompt will ask the user if they want to start tomcat.
tomcatStartPrompt()
{
echo
echo "Operation has finished."
echo "Would you like to start Tomcat now?"
yesNo
if [ "${yesNo}" = "yes" ]
then
	startTomcat
elif [ "${yesNo}" = "no" ]
then
	echo "Tomcat will not be started."
fi
}

# The tomcatStopPrompt will ask the user if they want to stop tomcat.
tomcatStopPrompt()
{
echo
echo "Stopping Tomcat is highly recommended."
echo "Would you like to stop Tomcat now?"
yesNo
if [ "${yesNo}" = "yes" ]
then
	stopTomcat
elif [ "${yesNo}" = "no" ]
then
	echo "You've been warned! Tomcat will not be stopped."
fi
}

# Restarts Tomcat
restartTomcat()
{
systemctl restart jamf.tomcat8.service
}

# Starts Tomcat
startTomcat()
{
systemctl start jamf.tomcat8.service
}

# Stops Tomcat
stopTomcat()
{
systemctl stop jamf.tomcat8.service
}

# The checkUnzipBinary function will check if "unzip" is installed. unzip is needed to deploy the webapp
checkUnzipBinary()
{
if ! command -v unzip >/dev/null
then
	echo "The unzip binary is not installed."
	echo "Please install the unzip binary via apt-get or yum before running Jamf Pro Manager."
	exit 1
fi
}

# The exitPrep function clears variables containing passwords to eliminate a security risk
# when exiting the script
exitPrep()
{
echo "Clearing passwords from variables..."
mysqlRootPwd=""
dbPass=""
echo "Done."
exit 0
}

# Main menu
function mainMenu()
{
echo
echo
echo "What would you like to do?"
echo
echo "1 Deploy a new Jamf Pro context"
echo "2 Upgrade an existing Jamf Pro context"
echo "3 Upgrade ALL Jamf Pro contexts"
echo "4 Delete an existing Jamf Pro context"
echo "5 Display all Jamf Pro contexts"
echo "6 Restart Tomcat"
echo "7 Start Tomcat"
echo "8 Stop Tomcat"
echo "9 Exit"
echo

installType=""

read -r -p "Enter your choice: " installType
case "${installType}" in
	1)
		echo "Deploying a new Jamf Pro..."
		newContext
	;;

	2)
		echo "Upgrading an existing Jamf Pro..."
		updateWebapp
	;;

	3)
		echo "Upgrading ALL Jamf Pro contexts..."
		updateAll
	;;

	4)
		echo "Deleting an existing Jamf Pro..."
		deleteMenu
	;;

	5)
		displayAll
	;;

	6)
		restartTomcat
		mainMenu
	;;

	7)
		startTomcat
		mainMenu
	;;

	8)
		stopTomcat
		mainMenu
	;;

	9)
		echo "Exiting..."
		exitPrep
	;;

	*)
		echo "Invalid Selection!"
		mainMenu
	;;
esac
}

##########################################################################################
#################################### End functions #######################################
##########################################################################################

# Trap [Ctrl+C] to clear passwords from variables when forcing exit

trap 'exitPrep && exit 5' 2

# Create log file

NOW="$(date +"%Y-%m-%d-%H-%M")"
echo "Creating ${logLocation}/$NOW.jssmanager.log..."
touch "${logLocation}/$NOW.jssmanager.log"

# Redirect stderr to stdout and print all to log

exec 2>&1 > >(tee "${logLocation}/$NOW.jssmanager.log")

clear

echo "Jamf Pro Manager v3.0.0"
echo "Copyright (C) 2013-2019 kitzy.org"
echo "Jamf Pro Manager comes with ABSOLUTELY NO WARRANTY."
echo "This is free software, and you are welcome to modify or redistribute it"
echo "under certain conditions; see the GNU General Public License for details."

checkRoot

checkWebapp

checkTomcat

checkUnzipBinary

echo
echo
echo "Welcome to the Jamf Pro Manager!"

mainMenu
