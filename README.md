# UpdateApps
Update apps by comparing versions to versions listed in this script.

ABOUT
This script will check the version of applications installed on a workstation.  If a newer version is available, if the application is installed and not in use, the script will update it.  

IMPLEMENTATION
Create a policy in your JSS for each application you want to update.  For example, if you want FireFox updated on each computer, create a policy called 'update firefox'.  Create a custom trigger for that policy with a name of your choice such as 'updatefirefoxstandard'.

Create a policy to install versioncompare.py on workstation.  Update the UpdateApps.sh script to point to the path where it is installed.  By default UpdateApps.sh looks in /Library/Application\ Support/JAMF/Partners/Library/Scripts/VersionCompare.py.  Chage the two lines at the top of the script to point to the location of VersionCompare.py on your machines.  

At the bottom of the script is a list of 'Update' lines.  You'll need to change the last two parts of each of those lines.  The 2nd to last part is the 'latest version'.  That's the latest version of the program that is on the JSS Server.  The last part of that is the JSS Custom trigger to update that app.  In the example above, that is called 'updatefirefoxstandard'.  If the user's workstation has an older version of firefox installed on their machine as compared to the version in the script, then the 'udpatefirefoxstand' policy will be called.

AppleSoftwareUpdate will be run at the end to install Apple supplied updates.

ADDITIONAL TOOLS
I recompiled Terminal-Notifier with a custom icon and called it PEAS-Notifier in our environment.  This script will look for that program.  If it not available, it will use JamfHelper.  PEAS-Notifier is optional.

NEW VERSIONS
When an application has a new version released, update the policy for that application to install the new version.  Then update the script with the new version number.  