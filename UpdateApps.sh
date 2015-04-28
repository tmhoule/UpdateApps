#!/bin/sh
# Original version written by Jason at Newton Public Schools
# Updated and Modified by Todd Houle at Partners Healthcare
# 1-20-2015
# 3-30-2015  fix apple softwareupdate function, and reboot
# 4-28-2015  Added Notification level options.
# UpdateApps.sh

# Copy down VersionCompare.py for later use.  It is used to compare versions of software to know if they need updating
if [ ! -f "/Library/Application Support/JAMF/Partners/Library/Scripts/VersionCompare.py" ]; then
    logger "UpdateApps: VersionCompare Needed.  Installing now.."
    jamf policy -event versioncompare
fi
chmod +x /Library/Application\ Support/JAMF/Partners/Library/Scripts/VersionCompare.py

logger "UpdateApps: Starting 42815.1305"
### Define function for updating most apps###
update(){
    # Rename function arguments for easier reference
        appName="$1" # The way the package is named in CasperShare i.e. Google Chrome
        appPath="$2" # In format /Applications/Google Chrome.app - no trailing slash
        versionString="$3" # The version we want to compare
	latestVersion="$4" #The latest version of the app
	policyToRun="$5"  #The policy to run to get latest version
	
	logger "UpdateApps: Processing $appName"
	# Only do all of this if the app is installed and is not currently running
	    # Define version installed on local machine
	if [ "$appName" == "Microsoft Office" ]; then
	    installedVersion=`defaults read "$appPath/Microsoft Word.app/Contents/Info.plist" |grep "$versionString" |awk '{print $3}'|sed -e 's/\"//g'|sed -e 's/;//g'`
	else
	    installedVersion=`defaults read "$appPath/Contents/Info.plist" | grep "$versionString" |awk '{print $3}'|sed -e 's/\"//g'|sed -e 's/;//g'`
	fi
	# For logging - print out current version
	echo ">>>Currently installed version of $appName is $installedVersion"
	# Install update if needed
	if [[ -d $appPath ]]; then
	    if [[ $(/Library/Application\ Support/JAMF/Partners/Library/Scripts/VersionCompare.py $latestVersion $installedVersion) -eq 1 ]] || [[ -L $appPath ]]; then
		if [[ `ps auxw | grep "$appPath" | grep -v "Syncplicity" |grep -v "Database Daemon"| grep -v "Microsoft AutoUpdate" |grep -v "SyncServicesAgent"|grep -v "Java Updater.app" |grep -v grep` == "" ]]; then
		    if [[ "$appPath" == "/Applications/Microsoft Office 2011" ]]; then
			if [[ `ps auxw |grep -i chrome | grep -v grep` == "" ]] && [[ `ps auxw |grep -i firefox | grep -v grep` == "" ]]; then
			    notify "$appName is being updated to version $latestVersion" 3
			    echo ">>>Update of $appName is needed. Installing $appName $latestVersion"
			    /usr/sbin/jamf policy -event $policyToRun
			    logger "UpdateAppsUPDATE: PEAS Updater is updating $appName"

			else
			    notify "FireFox or Chrome cannot be running when updating MS Office.  Please close them and try again" 3
			    logger "UpdateApps: Cant update Office when web browsers are running. Ask Microsoft why."
			fi
		    elif [[ "$appPath" == "/Applications/Firefox.app" ]]; then
				#if running Firefox, see if it is ESR version.  If so, rename it and move on.
                        esrTrue=`cat /Applications/Firefox.app/Contents/MacOS/application.ini |grep SourceRepository|grep esr`
			if [ -z $esrTrue ]; then    #-z means if variable is null(it's not ESR version)
			    logger "UpdateAppsUPDATE: $appName is being updated to version $latestVersion"
                            notify "$appName is being updated to version $latestVersion" 3
                            echo ">>>Update of $appName is needed. Installing $appName $latestVersion"
                            /usr/sbin/jamf policy -event $policyToRun
			else
			    logger "UpdateApps: FireFox ESR version found named as Firefox.  Renaming"
			    notify "FireFox ESR version found named as 'Firefox'.  Ranaming to 'FireFox ESR.'"
			    `mv /Applications/FireFox.app /Applications/Firefox\ ESR.app`
			fi
		    else
			logger "UpdateAppsUPDATE: $appName is being updated to version $latestVersion"
			notify "$appName is being updated to version $latestVersion" 3
			echo ">>>Update of $appName is needed. Installing $appName $latestVersion"
			/usr/sbin/jamf policy -event $policyToRun
		    fi
		else
		    logger "UpdateApps: $appPath is currently running. Cannot update."
		    echo ">>>$appPath is currently running. Cannot update."
		    RUNNINGAPPSARRAY+=("$appName")
		fi
	    else
		logger "UpdateApps: no update of $appName is needed"
		notify "No update of $appName is needed." 5
		echo ">>>No update of $appName is needed."
	    fi
	else
	    echo ">>>$appPath is not installed on this machine"
	    logger "UpdateApps: $appPath is not installed on this machine"
	fi
}


#### Routine to give feedback
notify(){
    loggedInUser=$( ls -l /dev/console | awk '{print $3}' )
    message="$1"
    verbosity="$2"

    if [[ "$loggedInUser" != "root" ]]; then    #display box only if someone logged in                                                                                                                
	if [ $userVerbosityChoice -ge $verbosity ]; then
	    /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType hud -windowPosition ll -title "PEAS Updates" -heading "PEAS Software Updates" -description "$message" -timeout 3 -button1 "Close"
	fi
    fi
}


updateAppleSW(){
    notify "Checking for Apple Software Updates." 5
    logger "UpdateApps: Processing Apple Software Updates"
    echo "Checking for Apple Software Updates"

    updateList=`softwareupdate -l 2>&1`  #2>&1 redirects stderr to stdout so it'll be available to grep.  No New software available is a STDERR message instead of STDOUT
    rebootNeeded=`echo "$updateList" |grep -A1 \*|grep restart`
    updatesNeeded=`echo "$updateList" |grep "No new software available"`
    loggedInUser=$( ls -l /dev/console | awk '{print $3}' )    
    
     ##Run AppleSoftwareUpdates 
    
    asuReboot="5"  #set with default value to not reboot.
    if [[ ! $updatesNeeded =~ "No new software available" ]]; then
        if [[ "$rebootNeeded" == "" ]]; then
            notify "Applying Required Apple OS Updates..." 5
            `/usr/sbin/softwareupdate -ir > /dev/null 2>&1`
	    logger "UpdateApps: Applying Apple Software Updates"
        else
            if [[ "$loggedInUser" != "root" ]]; then    #display box only if someone logged in 
                /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType hud -windowPosition ll -title "PEAS Updates" -heading "Reboot Required" -description "Apple Software Updates require a reboot. Click Apply to install updates.  The computer will REBOOT AUTOMATICALLY when updates have been installed." -button1 "Apply" -button2 "Skip" defaultButton 1
		asuReboot=$?
            else    #if nobody is logged in, then just run ASU!   
                $asuReboot="0"
            fi
	    if [ "$asuReboot" == "0" ]; then
                `/usr/sbin/softwareupdate -ir > /dev/null 2>&1`
            fi
        fi
    else
	notify "No Apple Updates Needed." 5
    fi
}


### routine to respond if an app was running and couldn't be updated.
runningapps(){
    count=`echo ${#RUNNINGAPPSARRAY[@]}`   #count items in array of apps in use and need updating
    inUseApps=`echo "${RUNNINGAPPSARRAY[@]}" | tr '\n' ' '`
    
    if [[ $count -eq 0 ]]; then
	echo ">> No in use programs need updating.  Awesome!"
	logger "UpdateApps: No in use programs need updating.  Awesome!"
    elif [[ $count -ge 2 ]]; then
        result=`/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -title "PEAS Updates" -heading "Programs in Use" -description "The applications $inUseApps need updating but are in use.  Please quit those programs and try again." -button2 "Skip" -button1 "Retry" -default button2`
        if [ "$result" == "0" ]; then
            checkForUpdates
        fi
    else
	result=`/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -title "PEAS Updates" -heading "Programs in Use" -description "The application ${RUNNINGAPPSARRAY[@]} needs updating but it is in use.  Please quit that program and try again." -button2 "Skip" -button1 "Retry" -default button2`
	if [ "$result" == "0" ]; then
	    checkForUpdates
	fi
    fi
}

### Call function for each regular app ###   
##AppPath is where to find the application   
# Location of version string is the identifier in the plist that contains the app version    
## latest version is the version of the app on the PEAS server - If version on peas server is newer, local version will be updated     
## JAMFPolicy is the name of the policy that will be run if local version is older than server version 
checkForUpdates(){
    #commented out for less verbosity
    #notify "Checking Applications for required updates."
    
    RUNNINGAPPSARRAY=()
    
    #         App Name           App Path                    Location of ver vers      lastest ver     JamfPolicyToGetLatest    
    update "GoogleChrome" "/Applications/Google Chrome.app" "CFBundleShortVersionString" "42.0.2311.90" "GoogleChrome"
    update "Adobe Flash Player" "/Library/Internet Plug-Ins/Flash Player.plugin" "CFBundleShortVersionString" "17.0.0.134" "AdobeFlash"
    update "Firefox ESR" "/Applications/Firefox ESR.app" "CFBundleShortVersionString" "31.6.0" "FireFoxESR"
    update "Firefox" "/Applications/Firefox.app" "CFBundleShortVersionString" "37.0.1" "FireFox"
    update "Enterprise Vault" "/Library/PreferencePanes/Enterprise Vault.prefPane" "CFBundleShortVersionString" "11.0.1" "SymEV"
    update "OracleJava7" "/Library/Internet Plug-Ins/JavaAppletPlugin.plugin" "CFBundleVersion" "1.8.40.25" "Java"
    update "Syncplicity" "/Applications/Syncplicity.app" "CFBundleVersion" "3.4.20.19" "Syncplicity"
    update "Cisco AnyConnect" "/Applications/Cisco/Cisco AnyConnect Secure Mobility Client.app" "CFBundleShortVersionString" "3.1" "CiscoVPN"
    update "Microsoft Office" "/Applications/Microsoft Office 2011" "CFBundleShortVersionString" "14.4.8" "OfficeUpdate"
    update "Adobe Acrobat" "/Applications/Adobe Acrobat XI Pro/Adobe Acrobat Pro.app" "CFBundleShortVersionString" "11.0.10" "AcrobatProUpdate"
    update "VLC" "/Applications/VLC.app" "CFBundleShortVersionString" "2.2.0" "vlc"
    update "FileMaker Pro 13" "/Applications/FileMaker Pro 13/FileMaker Pro.app" "CFBundleShortVersionString"  "13.0.5" "filemaker13update"
    runningapps   #presents option to retry apps that were running
}



##########################################################
### MAIN SECTION TO START THE WORK OF ROUTINES ABOVE  ####
##########################################################

#Determine user verbosity choice.   1 is quiet,   3 is notice    5 is Verbose
#set verbosity using other tool
#Example: defaults write /Library/Preferences/org.Partners.PEASManagement.plist updateAppVerbosity 3
userVerbosityChoice=`defaults read /Library/Preferences/org.Partners.PEASManagement.plist updateAppVerbosity`
if [ -z $userVerbosityChoice ]; then    #-z means if variable is null(noVerbosity defined by user)
    $userVerbosityChoice=3
fi
re='^[1-5]+$'  #defines regular expression to validate verbosity is number as expected.
if ! [[ $userVerbosityChoice =~ $re ]] ; then
   echo "UpdateApps: Error: User selected verbosity is not 1 through 5.  Setting to 3"
    $userVerbosityChoice=3
fi
logger "UpdateApps: User selected verbosity is $userVerbosityChoice"

notify "Beginning Application Updates...  Checking Applications." 5

checkForUpdates  #routine to check and update apps

### At end, call function for Apple updates  
updateAppleSW

#notify "Finalizing Updates"
logger "UpdateApps: Finalizing updates with Recon"
`/usr/sbin/jamf recon > /dev/null 2>&1`   
if [ "$asuReboot" == "0" ]; then
    notify "All Updates have completed.  Rebooting now!" 1
    logger "UpdateApps: Completed.  Rebooting.."
    sleep 5
    `/sbin/reboot`
else
    notify "All Updates have completed." 5
    logger "UpdateApps: Completed."
fi
