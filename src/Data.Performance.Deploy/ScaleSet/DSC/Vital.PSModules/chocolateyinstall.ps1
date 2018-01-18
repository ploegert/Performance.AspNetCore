Begin
{

	function Import-DependentModules
	{
		#DSC via Choco does not see this file, causing pointless error. grrrrrr
		Copy-Item "$PSScriptRoot\WindowsPackageCab.Strings.psd1" "$env:windir\System32\WindowsPowerShell\v1.0\Modules\PSDesiredStateConfiguration\DSCClassResources\WindowsPackageCab" -Confirm:$false -Force;
	}


	$logFile = Join-Path $env:TEMP 'data.utils.vital.psmodules.log';
    if (-not (Test-Path $logFile))
    {
		New-Item $logFile -ItemType File -Force;
	}

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