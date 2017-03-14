# UpdateApps
Update apps by comparing versions to versions listed in this script.

## This script has been superceded by https://github.com/tmhoule/AppUpdates and is no longer being maintained.

ABOUT
This script will check the version of applications installed on a workstation.  If a newer version is available, if the application is installed and not in use, the script will update it.  

IMPLEMENTATION
Create a policy in your JSS for each application you want to update.  For example, if you want FireFox updated on each computer, create a policy called 'update firefox'.  Create a custom trigger for that policy with a name of your choice such as 'updatefirefoxstandard'.

Create a policy to install versioncompare.py on workstation.  Update the UpdateApps.sh script to point to the path where it is installed.  By default UpdateApps.sh looks in /Library/Application\ Support/JAMF/Partners/Library/Scripts/VersionCompare.py.  Chage the two lines at the top of the script to point to the location of VersionCompare.py on your machines.  

At the bottom of the script is a list of 'Update' lines.  You'll need to change the last two parts of each of those lines.  The 2nd to last part is the 'latest version'.  That's the latest version of the program that is on the JSS Server.  The last part of that is the JSS Custom trigger to update that app.  In the example above, that is called 'updatefirefoxstandard'.  If the user's workstation has an older version of firefox installed on their machine as compared to the version in the script, then the 'udpatefirefoxstand' policy will be called.

AppleSoftwareUpdate will be run at the end to install Apple supplied updates.

NEW VERSIONS
When an application has a new version released, update the policy for that application to install the new version.  Then update the script with the new version number.  

ADDING A NEW APPLICAITON
If you have a new program you would like to apply updates to, go to the bottom of the script and look for the paragraph of updates.  Create a new policy to deploy that program - be sure to include a 'custom' trigger.  Create a new line with the following information.
1) An identifiiable application name
2) The Path to find the program on the remote computer
3) The plist entry that contains the version.  You can get this by typing the following in terminal "defaults read /Application/MyFavoiteapp.app/Contents/Info.plist" then read through the output to find the version string.  It is usally CFBundleShortVersionString, but not necessarily.  
4) The latest version you have on your JSS
5) The policy 'custom event' to invoke if user has an older version than what you just listed in #4.  

USER NOTIFICATIONS
Now uses Peas-Notifier (a recompiled verison of Terminal Notifier).  Logging is now in /var/log/PeasAutoUpdateslog.log

Verbosity disabled: May2015  
May, 2015: Now using Apple Notification Center, so verbosity was disabled.  Nicer messages mean less reason to reduce verbosity.
