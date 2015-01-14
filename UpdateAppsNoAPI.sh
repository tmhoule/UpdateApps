#!/bin/sh
# Origonal version written by Jason at Newton Public Schools
# Updated and Modified by Todd Houle at Partners Healthcare
# 1-16-2015
# UpdateApps.sh

dp_url="peascaspernorth.partners.org/Packages"

# Copy down VersionCompare.py for later use
if [ ! -f /tmp/VersionCompare.py ]; then
    curl -s -o /tmp/VersionCompare.py http://$dp_url/VersionCompare.dmg
fi
chmod -R 777 /tmp/VersionCompare.py

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
       	    if [[ $(/tmp/VersionCompare.py $latestVersion $installedVersion) -eq 1 ]] || [[ -L $appPath ]]; then
		if [[ `ps auxw | grep "$appPath" | grep -v "Syncplicity" |grep -v "Database Daemon"|grep -v grep` == "" ]]; then
                    notify "$appName is being updated to version $latestVersion"
                    echo ">>>Update of $appName is needed. Installing $appName $latestVersion"
		    /usr/sbin/jamf policy -event $policyToRun
		    logger "PEAS Updater is updating $appName"
		else
		    echo ">>>$appPath is currently running. Cannot update."
		    notify "$appName needs updating but cannot as it is in use."
		    sleep 3
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
##Run AppleSoftwareUpdates
    notify "Updating Apple OS Software."
    neededSW=`softwareupdate -l | grep -A1 \*| tail -1`
    rebootMe=`echo $neededSW |grep restart`

    `/usr/sbin/softwareupdate -ir > /dev/null 2>&1`
    notify "Finalizing Updates"
    `/usr/sbin/jamf recon > /dev/null 2>&1`   

    if [[ "$rebootMe" == "" ]]; then
	notify "Updates have completed!"
    else
        notify "A REBOOT is REQUIRED.  Please Reboot your computer"
    fi
}

#######################################################
#######################################################
### Call function for each regular app ###   
##AppPath is where to find the application   
# Location of version string is the identifier in the plist that contains the app version    
## latest version is the version of the app on the PEAS server - If version on peas server is newer, local version will be updated     
## JAMFPolicy is the name of the policy that will be run if local version is older than server version 

#         App Name           App Path                    Location of ver vers      lastest ver     JamfPolicyToGetLatest    
update "GoogleChrome" "/Applications/Google Chrome.app" "CFBundleShortVersionString" "39.0.2171.99" "GoogleChrome"
update "Adobe Flash Player" "/Library/Internet Plug-Ins/Flash Player.plugin" "CFBundleShortVersionString" "16.0.0.257" "AdobeFlash"
update "Firefox ESR" "/Applications/Firefox ESR.app" "CFBundleShortVersionString" "31.3.0" "FireFoxESR"
update "Firefox" "/Applications/Firefox.app" "CFBundleShortVersionString" "35.0" "FireFox"
update "Enterprise Vault" "/Library/PreferencePanes/Enterprise Vault.prefPane" "CFBundleShortVersionString" "11.0.1" "SymEV"
update "OracleJava7" "/Library/Internet Plug-Ins/JavaAppletPlugin.plugin" "CFBundleVersion" "1.8.25.17" "Java"
update "Syncplicity" "/Applications/Syncplicity.app" "CFBundleVersion" "3.4.20.19" "Syncplicity"
update "Cisco AnyConnect" "/Applications/Cisco/Cisco AnyConnect Secure Mobility Client.app" "CFBundleShortVersionString" "3.1" "CiscoVPN"
update "Microsoft Office" "/Applications/Microsoft Office 2011" "CFBundleShortVersionString" "14.4.7" "OfficeUpdate"

### Call function for Apple updates  
updateAppleSW
