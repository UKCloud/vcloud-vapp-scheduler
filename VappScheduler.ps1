#####DO NOT EDIT BELOW THIS LINE####

. .\Config.ps1

function Log($message)
{
	$date = Get-Date -UFormat "%d-%m-%y %H:%M"
	$message = $date + " " + $message
	$message|out-file -FilePath $log -Append
	Write-Host $message
}

function SendEmail($message,$address)
{
	try
	{	
		Log "Sending Mail to $address"
		Send-MailMessage -Body $message -From $mailfromaddress -Subject "vApp Scheduler Notification" -To $address -smtpserver $mailserver
	}
	catch [System.Exception]
	{
		Log $Error[0].Exception.Message
	}

}

function ValidateTime($timeoff,$timeon)
{
	$timeon = $timeon.replace(":","")
	$timeoff = $timeoff.replace(":","")
	$now = get-date -UFormat %H%M
	#write-host "Now:$now On:$timeon Off:$timeoff"
	if($now -lt $timeon -or $now -gt $timeoff)
	{
		return $False
	}
	elseif($now -gt $timeon -and $now -lt $timeoff)
	{
		return $True
	}
}

function PowerOperation($operation,$vm)
{
	try
	{
		if ($operation -eq "On")
		{
			Log "Powering On $vmname"
			start-civm -VM $vm -Confirm:$false -RunAsync -EA "Stop"
		}
		elseif ($operation -eq "Off")
		{
			Log "Powering Off $vmname"
			stop-civm -VM $vm -Confirm:$false -RunAsync -EA "Stop"
		}
		else
		{
			Log "Invalid Power Operation For VM $vmname"
		}
	}
	catch
	{
		Log $Error[0].Exception.Message
		if ($notifyerrors)
		{
			SendEmail "Power Operation For VM $vmname Failed" $email
		}
	}
}


function GetCredentialsForOrg($orgid)
{
	$file = "$credentialstore\$orgid.cred"
	
	try
	{
		$credstrings = get-content -Path $file -EA "Stop"
		if($credstrings.length -ne 2)
		{
			write-error "Credentials File Format Incorrect, Re-Capture Credentials And Try Again"
		}
		$username=$credstrings[1]
		$pass = ConvertTo-SecureString $credstrings[0]
		
		$creds = New-Object System.Management.Automation.PsCredential($username, $pass)
		if(!$creds)
		{
			write-error "Failed To Get Creds For Org: $orgid"
		}
		return $creds
		
	}
	catch
	{
		Log $Error[0].Exception.Message
		if ($notifyerrors)
		{
			SendEmail "Failed To Retrieve Credentials For $orgid" $email
		}
	}
	
}

function Login($orgid,$creds,$url)
{
	try
	{
		Log "Logging In: $url OrgId: $orgid"
		Connect-CIServer -Org $orgid -Credential $creds -Server $url -EA "Stop" > $null
	}
	catch
	{
		Log $Error[0].Exception.Message
	}

}





try
{
	$vapplist = import-csv $vappfile |Sort-Object orgid
}
catch [System.Exception]
{
	Log($Error[0].Exception.Message)
}

$previousorgid = ""
foreach ($vapp in $vapplist)
{
	
	$vappname = $vapp.vappName
  $vmname = $vapp.vmName
	$timeon = $vapp.timeOn
	$timeoff = $vapp.timeOff
	$email = $vapp.notifyEmail
	$orgid = $vapp.orgId
  $url = $vapp.url
write-host $orgid	
	$creds = GetCredentialsForOrg $orgid
	if ($creds -AND $orgid -ne $previousorgid)
	{
		Login $orgid $creds $url
	}
	Log "Processing vApp: $vappname"
	$poweredon = $True
	try
	{
		$vapp = get-civapp -Name $vappname -EA "Stop"
		$vm = get-civm -Name $vmname -VApp $vapp -EA "Stop"
		if($vm.status -ne "PoweredOff")
		{
			$poweredon = $True
			Log "	$vmname is currently Powered On"
		}
		else
		{
			$poweredon= $False
			Log "	$vmname is currently Powered Off"
		}
		
		$expectedstatus = ValidateTime $timeoff $timeon
		if($poweredon -ne $expectedstatus)
		{
			
			if($expectedstatus)
			{
				Log "	$vmname Should Be Powered On"
				PowerOperation "On" $vm
				
				
			}
			else
			{
			Log "	$vmname Should Be Powered Off"
				PowerOperation "Off" $vm

			}
		}
		else
		{
			Log "	$vmname is in the expected power state"
		}
	}
	catch 
	{
		Log $Error[0].Exception.Message
	}

	
	
	$previousorgid = $orgid
	
}
