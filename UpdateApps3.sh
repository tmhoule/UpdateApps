#!/bin/sh
# Original version written by Jason at Newton Public Schools
# Updated and Modified by Todd Houle at Partners Healthcare
# 1-20-2015
# UpdateApps.sh


# Copy down VersionCompare.py for later use.  It is used to compare versions of software to know if they need updating
if [ ! -f "/Library/Application Support/JAMF/Partners/Library/Scripts/VersionCompare.py" ]; then
    jamf policy -event versioncompare
fi
chmod +x /Library/Application\ Support/JAMF/Partners/Library/Scripts/VersionCompare.py


### Define function for updating most apps###
update(){
    # Rename function arguments for easier reference
        appName="$1" # The way the package is named in CasperShare i.e. Google Chrome
        appPath="$2" # In format /Applications/Google Chrome.app - no trailing slash
        versionString="$3" # The version we want to compare
	latestVersion="$4" #The latest version of the app
	policyToRun="$5"  #The policy to run to get latest version

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
		    if [[ `ps auxw | grep "$appPath" | grep -v "Syncplicity" |grep -v "Database Daemon"|grep -v grep` == "" ]]; then
			if [[ "$appPath" == "/Applications/Microsoft Office 2011" ]]; then
			    if [[ `ps auxw |grep -i chrome | grep -v grep` == "" ]] && [[ `ps auxw |grep -i firefox | grep -v grep` == "" ]]; then
				notify "$appName is being updated to version $latestVersion"
                                echo ">>>Update of $appName is needed. Installing $appName $latestVersion"
				/usr/sbin/jamf policy -event $policyToRun
				logger "PEAS Updater is updating $appName"
				
			    else
				notify "FireFox or Chrome cannot be running when updating MS Office.  Please close them and try again"
			    fi
			else
			    notify "$appName is being updated to version $latestVersion"
			    echo ">>>Update of $appName is needed. Installing $appName $latestVersion"
			    /usr/sbin/jamf policy -event $policyToRun
			    logger "PEAS Updater is updating $appName"
			fi
		    else
			echo ">>>$appPath is currently running. Cannot update."
			RUNNINGAPPSARRAY+=("$appName")
		    fi
		else
		    echo ">>>No update of $appName is needed."
		fi
	else
	    echo ">>>$appPath is not installed on this machine"
	fi
}


#### Routine to give feedback
notify(){
    message="$1"
    #PEAS-Notifer is Todd's bastardized version of Terminal-Notifier app
    if [ -f "/Library/Application Support/JAMF/Partners/PEAS-Notifier.app/Contents/MacOS/PEAS-Notifier" ]; then
	/Library/Application\ Support/JAMF/Partners/PEAS-Notifier.app/Contents/MacOS/PEAS-Notifier -message "$message" -title "PEAS Updates"
    else
	/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType hud -windowPosition ll -title "PEAS Updates" -heading "PEAS Software Updates" -description "$message" -timeout 5
   fi
}


updateAppleSW(){
#    notify "Checking Apple OS Software."
    updateList=`softwareupdate -l 2>&1`  #2>&1 redirects stderr to stdout so it'll be available to grep.  No New software available is a STDERR message instead of STDOUT
    rebootNeeded=`echo "$updateList" |grep -A1 \*|grep restart`
    updatesNeeded=`echo "$updateList" |grep "No new software available"`
    
    ##Run AppleSoftwareUpdates                                                                                                                                                                                                                                                                                                                                  
    if [[ ! $updatesNeeded =~ "No new software available" ]]; then
	if [[ "$rebootNeeded" == "" ]]; then
	        notify "Applying Apple OS Updates..."
            `/usr/sbin/softwareupdate -ir > /dev/null 2>&1`   
	    else
            asuReboot=`/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType hud -windowPosition ll -title "PEAS Updates" -heading "Reboot Required" -description "Updates require a reboot. Please reboot your computer to finalize updates." -button1 "Apply" -button2 "Skip" defaultButton 1`
            if [ $asuReboot == 0 ]; then
		`/usr/sbin/softwareupdate -ir > /dev/null 2>&1`
		#/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType hud -windowPosition ll -title "PEAS Updates" -heading "PEAS Software Updates" -description "Updates have been applied to your computer and require a reboot. Please reboot your computer using the Apple menu on the top left of your screen." -button1 "OK" defaultButton 1
            fi
	    fi
    else
	echo "No Apple OS updates Needed"
    fi
}



### routine to respond if an app was running and couldn't be updated.
runningapps(){
    count=`echo ${#RUNNINGAPPSARRAY[@]}`   #count items in array of apps in use and need updating
    inUseApps=`echo "${RUNNINGAPPSARRAY[@]}" | tr '\n' ' '`

    if [[ $count -eq 0 ]]; then
	echo ">> No in use programs need updating.  Awesome!"
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
    notify "Checking Applications for required updates."
    sleep 2
    
    RUNNINGAPPSARRAY=()
    
    #         App Name           App Path                    Location of ver vers      lastest ver     JamfPolicyToGetLatest    
    update "GoogleChrome" "/Applications/Google Chrome.app" "CFBundleShortVersionString" "40.0.2214.111" "GoogleChrome"
    update "Adobe Flash Player" "/Library/Internet Plug-Ins/Flash Player.plugin" "CFBundleShortVersionString" "16.0.0.305" "AdobeFlash"
    update "Firefox ESR" "/Applications/Firefox ESR.app" "CFBundleShortVersionString" "31.3.0" "FireFoxESR"
    update "Firefox" "/Applications/Firefox.app" "CFBundleShortVersionString" "35.0.1" "FireFox"
    update "Enterprise Vault" "/Library/PreferencePanes/Enterprise Vault.prefPane" "CFBundleShortVersionString" "11.0.1" "SymEV"
    update "OracleJava7" "/Library/Internet Plug-Ins/JavaAppletPlugin.plugin" "CFBundleVersion" "1.8.31.13" "Java"
    update "Syncplicity" "/Applications/Syncplicity.app" "CFBundleVersion" "3.4.20.19" "Syncplicity"
    update "Cisco AnyConnect" "/Applications/Cisco/Cisco AnyConnect Secure Mobility Client.app" "CFBundleShortVersionString" "3.1" "CiscoVPN"
    update "Microsoft Office" "/Applications/Microsoft Office 2011" "CFBundleShortVersionString" "14.4.8" "OfficeUpdate"
    runningapps   #presents option to retry apps that were running
}



##########################################################
### MAIN SECTION TO START THE WORK OF ROUTINES ABOVE  ####
##########################################################
checkForUpdates  #routine to check and update apps

### At end, call function for Apple updates  
updateAppleSW

notify "Finalizing Updates"
`/usr/sbin/jamf recon > /dev/null 2>&1`   
notify "All Updates Have Completed."
if [ $asuReboot == 0 ]; then
    `/sbin/reboot`
fi
