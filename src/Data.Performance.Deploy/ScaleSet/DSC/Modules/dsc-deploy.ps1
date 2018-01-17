Configuration SetupVitalModules
{
	Import-DscResource -ModuleName PSDesiredStateConfiguration;

	Node localhost
	{
        $xComputerManagement = "$PSScriptRoot\modules\xComputerManagement";
        $xNetworking = "$PSScriptRoot\modules\xNetworking";
        $xPSDesiredStateConfiguration = "$PSScriptRoot\modules\xPSDesiredStateConfiguration";
        $xRemoteDesktopAdmin = "$PSScriptRoot\modules\xRemoteDesktopAdmin";
        $xRobocopy = "$PSScriptRoot\modules\xRobocopy";
        $xSystemSecurity = "$PSScriptRoot\modules\xSystemSecurity";
        $xWebAdministration = "$PSScriptRoot\modules\xWebAdministration";
        $psModulePath = "$($env:PSModulePath.Split(';') -like "*\Program Files\WindowsPowerShell\Modules*" | select -First 1)"
        
        File xComputerManagement
        {
            SourcePath = $xComputerManagement
            DestinationPath = "$psModulePath\xComputerManagement"
            Recurse = $true
            Type = 'Directory'
            MatchSource = $true
            Checksum = 'SHA-256'
            Force = $true
            Ensure = 'Present'
        }
             
        File xNetworking
        {
            SourcePath = $xNetworking
            DestinationPath = "$psModulePath\xNetworking"
            Recurse = $true
            Type = 'Directory'
            MatchSource = $true
            Checksum = 'SHA-256'
            Force = $true
            Ensure = 'Present'
        }
        
        
        File xPSDesiredStateConfiguration
        {
            SourcePath = $xPSDesiredStateConfiguration
            DestinationPath = "$psModulePath\xPSDesiredStateConfiguration"
            Recurse = $true
            Type = 'Directory'
            MatchSource = $true
            Checksum = 'SHA-256'
            Force = $true
            Ensure = 'Present'
        }
        
        File xRemoteDesktopAdmin
        {
            SourcePath = $xRemoteDesktopAdmin
            DestinationPath = "$psModulePath\xRemoteDesktopAdmin"
            Recurse = $true
            Type = 'Directory'
            MatchSource = $true
            Checksum = 'SHA-256'
            Force = $true
            Ensure = 'Present'
        }
        
        
        File xRobocopy
        {
            SourcePath = $xRobocopy
            DestinationPath = "$psModulePath\xRobocopy"
            Recurse = $true
            Type = 'Directory'
            MatchSource = $true
            Checksum = 'SHA-256'
            Force = $true
            Ensure = 'Present'
        }
        
        
         File xSystemSecurity
        {
            SourcePath = $xSystemSecurity
            DestinationPath = "$psModulePath\xSystemSecurity"
            Recurse = $true
            Type = 'Directory'
            MatchSource = $true
            Checksum = 'SHA-256'
            Force = $true
            Ensure = 'Present'
        }
        
        File xWebAdministration
        {
            SourcePath = $xWebAdministration
            DestinationPath ="$psModulePath\xWebAdministration"
            Recurse = $true
            Type = 'Directory'
            MatchSource = $true
            Checksum = 'SHA-256'
            Force = $true
            Ensure = 'Present'
        }
	}
}
SetupVitalModules -OutputPath "${env:ProgramFiles(x86)}\WindowsPowerShell\Configuration";
Start-DscConfiguration -Path "${env:ProgramFiles(x86)}\WindowsPowerShell\Configuration" -Wait -Verbose -Force;