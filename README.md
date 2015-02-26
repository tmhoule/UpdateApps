# UpdateApps
Update apps by comparing versions on the JSS

ABOUT
This script will check the version of applications installed on a workstation.  If a newer version is available, if the application is installed and not in use, the script will update it.  

IMPLEMENTATION
At the bottom of the script is a list of 'Update' lines.  You'll need to change the last two parts of each of those lines.  The 2nd to last part is the 'latest version'.  That's the latest version of the program that is on the JSS Server.  The last part of that is the JSS Custom trigger to update that app.  

So Install a new app on your JSS, say Firefox which has weekly updates.  Create a policy to install that program with a custom trigger (for example, InstallFireFox).  You'll also need to put the VersionCompare.py script available.  I put it in my file repository, then had the script download it.  You can come up with your own solution depending on your environment.  Finally update the 'update' line at the bottom of this script with the new version of Firefox.  Then run this script.  If the machine has an older version, this script will run the policy 'InstallFireFox' which will install the new version.  It then runs AppleSoftwareUpdate and notifies the user if a reboot is needed.  

You'll also need to make sure VersionCompare.py is on each machine.  I use a JAMF policy to pull it down if it is not in a specific directory on the Mac.  You can handle that requirement as appropriate for your envioronment. 

ADDITIONAL TOOLS
I recompiled Terminal-Notifier with a custom icon and called it PEAS-Notifier in our environment.  This script will look for that program.  If it not available, it will use JamfHelper.  It is optional
