<h1>vCloud vApp Scheduler</h1>

Powershell scripts to power vcloud Director VMs on and off according to a schedule.

<h2>Introduction</h2>
<p>
Many customers wish to take advantage of the UKCloud’s hourly billing by turning VMs off when they are not in use. Currently there is no global functionality in the Skyscape platform to automate this for customers however it can be relatively easily achieved using the vCloud Director API.
To assist customers with this UKCloud have written a PowerShell script which allows a range of VMss to be powered on and off according to a schedule. This document explains how the process works and what is required to install and configure the script.
</p>
<h2>How It Works</h2>

<p>Customers create a CSV (vapplist.csv) file containing a list of VMs which need controlling along with their Organization ID and the time at which each VM should be powered on or off.
Customers run the “SaveCredentials.ps1” script to capture the Organization login credentials to an encrypted file in the “creds” directory
Customers configure a Windows scheduled task to run the vAppScheduler.ps1 script at regular intervals (every 5 minutes or so)
Every 5 minutes (or whatever interval was specified) the script cycles through “vapplist.csv” logging in to vCloud Orgs to check whether the VM is running or not. If the time window specified in “vapplist.csv” dictates that VM should be running and the script deems that it is not then the script will start the VM immediately. Likewise if the script deems that the VM should not be running then it will stop it immediately.
</p>

<h2>Requirements</h2>

<ul>
<li>A Tiny Windows VM which supports running PowerShell scripts</li>
<li>VMware PowerCLI  5.0 or later</li>
<li>Login Credentials for each vCloud Organization hosting VMs you wish to automate</li>
<li>The vAppScheduler.ps1 script</li>
<li>The SaveCredentials.ps1 script</li>
</ul>

<h2>Getting Started:</h2>

<h3>1. Install git on your local machine:</h3>
http://git-scm.com/book/en/v2/Getting-Started-Installing-Git

<h3>2. Install PowerCLI</h3>
http://buildvirtual.net/install-and-configure-vsphere-powercli-5-x/

<h3>3. Open PowerCLI and clone this repository</h3>
`git clone https://github.com/tlawrence/scripts`

<h3>4. Create a directory to store scripts and config & copy scripts over</h3>

`PowerCLI C:\GIT\scripts> mkdir c:\automation  
`PowerCLI C:\GIT\scripts> copy vapp_scheduler\*.ps1 c:\automation`


<h3>5. Change directory and create 'creds' subdirectory</h3>

`PowerCLI C:\GIT\scripts> cd c:\automation  
PowerCLI C:\GIT\scripts> mkdir creds`


<h3>6. Create a scheduled task to run vAppScheduler.ps1 frequently (every 5 minutes is recommended)</h3>

This step will vary based on the version of Windows / PowerCLI you are running. The command will probably need to look something like the following though:

`C:\WINDOWS\system32\windowspowershell\v1.0\powershell.exe  -noexit -command c:\automation\VappScheduler.ps1`  

<h3>7. Configure global script settings</h3>

The VappScheduler.ps1 script reads a file called 'config.ps1' when it runs. This configures global settings such as mail server for notifications etc. An example file is available in this git repository. this file needs to be created and configured. The VappScheduler.ps1 script expects to find it in the local directory

Config.ps1:  

`$credentialstore = "c:\automation\creds"`  
`$log = "vappcontrol.log"`  
`$vappfile = "c:\automation\vapplist.csv"`  
`$mailfromaddress = "admin@yourcompany.com"`  
`$mailserver = "smtp.yourcompany.local"`  
`$notifyerrors = $true`


<h2>Saving credentials for vCloud Orgs</h2>	
Each vCloud Org which contains VMs to schedule will need a set of credentials saving. The script 'SaveCredentials.ps1' is provided to securely capture credentials to the 'creds' directory

SaveCredentials.ps1 should be run from a Powershell Prompt. The script will prompt you to enter the orgid (eg 000-ff-0976). Once you have entered the orgid the script will display a credentials dialogue box. In username enter the API username as viewable in the top right hand corner of Skyscape Portal under your username and the API button. The password is the same as your Skyscape Portal login password.

`PowerCLI C:\automation>SaveCredentials.ps1  
Enter Org ID  
1-129-2-6sd32  
Enter Credentials`

A file named '1-129-2-6sd32.cred' will be saved in the 'creds' directory


<h2>Configuring vApps for a schedule</h2>
The main script looks for a csv file called 'vapplist.csv'. This file contains a list of vApps, the time they should be powered on and the time they should be powered off. The script then calculates the expected status of the vApp at any particular time and issues commands to vCloud Director to ensure the correct status is applied.

The file should take the following format (example in GIT repo):  
`    vappName ,          vmname , timeOn , timeOff ,     notifyEmail      ,    orgId      , url`  
`    testvapp1 ,          vm1    , 07:20  ,  08:20  , tlawrence@github.com , 000-ff-097f6 , api.vcd.yourcloud.com`  
`    testvapp2 ,         vm2    , 00:00  ,  23:59  , tlawrence@github.com , 000-ff-097f6  , api.vcd.yourcloud.com`  
`vapp_in_other_org ,     vm3    , 10:00  ,  11:00  , tlawrence@github.com , 1-1-1-a356h   , api.vcd.someothercloud.com`
