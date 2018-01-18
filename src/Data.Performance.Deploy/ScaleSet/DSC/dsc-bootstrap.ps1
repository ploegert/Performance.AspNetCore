# deploy-ARM.ps1 ==> Invokes arm template to Deploy Base resources from ARM Template & Run Extensions
#   ARM.PIP
#   ARM.Network
#   ARM.LoadBalancer
#   ARM.VMSS
#   ARM.VMSS.CustomScript 
#       ==> downloads dsc-bootstrap.ps1
#       ==> Invokes dsc-bootstrap.ps1 
#           ==> Downloads Vital.PSModules.zip
#           ==> Extracts Vital.PSModules
#           ==> Executes dsc-deploy
#               ==> Copies all the modules to the module folder
#   ARM.VMSS.DSCExecution
#       ==> Copies down Vital.IIS.zip
#       ==> Executes dsc-IIS-DefaultSite.ps1
#


Begin
{

	function Import-DependentModules
	{
		#DSC via Choco does not see this file, causing pointless error. grrrrrr
		Copy-Item "$PSScriptRoot\WindowsPackageCab.Strings.psd1" "$env:windir\System32\WindowsPowerShell\v1.0\Modules\PSDesiredStateConfiguration\DSCClassResources\WindowsPackageCab" -Confirm:$false -Force;
	}

    # Setup LogFile
	$logFile = Join-Path $env:TEMP 'data.utils.vital.psmodules.log';
    if (-not (Test-Path $logFile))
    {
		New-Item $logFile -ItemType File -Force;
	}

    # Start Transcript
    try
	{
		"Starting transcript: $logFile";
		Start-Transcript -Path $logFile -Append -Force -NoClobber | Out-Null;
	}
	catch
	{
		Stop-Transcript;
		Start-Transcript -Path $logFile -Append -Force -NoClobber | Out-Null;
	}
    
    # Generate Lock File
    $lockFile= (Join-Path $env:TEMP 'ata.utils.vital.psmodules.lock');
    if ((Test-Path $lockfile) -and (Get-Item $lockFile).LastAccessTime -lt (Get-Date).AddDays(1)) 
    { 
		Write-Error 'A lock file is currently in place. Ensure there are no other processes running. We cannot continue and therefore must break. Go get a snickers bar...';
		Stop-Transcript;
		exit -1;
	}

	New-Item $lockFile -Type File -Value 'File locked for sync purposes' -Force;
}

Process
{
    try
    {
        #install-Module -Name xWebAdministration -Repository PSGallery -Force -Confirm:$False
                
        #Setup
        $zip_src_filepath = "https://raw.githubusercontent.com/ploegert/Performance.AspNetCore/master/src/Data.Performance.Deploy/ScaleSet/DSC/Vital.PSModules.zip"
        $zip_filename = split-path $zip_src_filepath -leaf
        $zip_dst_path = "C:\WindowsAzure\Applications\DSC-Setup"
        $zip_dst_filepath = join-path $zip_dst_path $zip_filename
        
        # Download file
        $WebClient = New-Object -TypeName System.Net.WebClient
        $WebClient.DownloadFile($zip_dst_filepath, $zip_dst_path)
        
        
        if(test-path $zip_dst_filepath)
        {
            #Extract File
            Expand-Archive -Path $zip_dst_filepath -DestinationPath $zip_dst_path
        
            #Execute File
            & "$zip_dst_path\chocolateyinstall.ps1";
        
        }
        else {
            write-error "The file didn't copy down for some reason. Better to consult help or something!"
        }


		'Setting up WinRM: (Pre-req for DSC Script)';
		winrm quickconfig -force;
			
		'Installing Dependent Powershell modules';
		Import-DependentModules;

		'Invoking DSC Script: ata.utils.vital.psmodules';
		& "$PSScriptRoot\dsc-deploy.ps1";
    }
    catch
    {
        Write-Error -Message("[{0,-20}-{1}] - {2}: {3}" -f ((Get-PSCallStack)[0].Command), (Get-Date), 'Error in Try/Catch Loop', $_.Exception.Message);
    }
    finally
    {
        Remove-Item $lockFile -Force;
	    Stop-Transcript;
    }
}

End
{

}