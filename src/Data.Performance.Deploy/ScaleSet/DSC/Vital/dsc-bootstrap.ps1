Configuration SetupBox
{
	Import-DscResource -ModuleName PSDesiredStateConfiguration;
    Import-DscResource -ModuleName xPSDesiredStateConfiguration;
	Import-DscResource -ModuleName xComputerManagement;
	Import-DSCResource -ModuleName xRemoteDesktopAdmin;
	Import-DSCResource -ModuleName xSystemSecurity;
	Import-DSCResource -ModuleName xNetworking;
	Import-DSCResource -ModuleName xWebAdministration;

	Node localhost
	{
		xPowerPlan PowerPlan
 		{
            Name = 'High Performance'
 			IsSingleInstance = 'Yes'
 		}

		xRemoteDesktopAdmin RemoteDesktopSettings
        {
			Ensure = 'Present'
			UserAuthentication = 'Secure'
        }

        xUAC NotifyChanges
        {
            Setting = 'NotifyChanges'
        }

		Script FirewallAllOn
		{
			TestScript = { return ('True' -in (Get-NetFirewallProfile -All).Enabled) }
            SetScript = {
				Set-NetFirewallProfile -All -Enabled True;
            }
            GetScript = { return @{} }
		}

        xFirewall AllowRDP
        {
            Name = 'RDP-3389-In'
            Group = 'JohnsonControls'
            Ensure = 'Present'
            Enabled = 'True'
            Direction = 'Inbound'
            LocalPort = '3389'
            Protocol = 'TCP'
            Description = 'Allows remote connections via RDP'
        }

		WindowsOptionalFeatureSet IISWebServerRole
		{
			Name = @(
              'IIS-WebServerRole', 'IIS-WebServer', 'IIS-ManagementConsole', 'IIS-WebServerManagementTools'
              'IIS-ISAPIExtensions', 'IIS-ISAPIFilter', 'NetFx4Extended-ASPNET45', 'IIS-NetFxExtensibility45', 'IIS-ASPNET45',
              'IIS-StaticContent', 'IIS-WebSockets'
			)
			Ensure = 'Enable'
		}
		WindowsOptionalFeature DisableIISDirBrowsing
        {
            Name = 'IIS-DirectoryBrowsing'
            Ensure = 'Disable'
        }

        xFirewall AllowHTTP
        {
            Name = 'IIS-80-In'
            Group = 'JohnsonControls'
            Ensure = 'Present'
            Enabled = 'True'
            Direction = 'Inbound'
            LocalPort = '80'
            Protocol = 'TCP'
            Description = 'Allows remote connections via HTTP'
        }
        xFirewall AllowHTTPS
        {
            Name = 'IIS-443-In'
            Group = 'JohnsonControls'
            Ensure = 'Present'
            Enabled = 'True'
            Direction = 'Inbound'
            LocalPort = '443'
            Protocol = 'TCP'
            Description = 'Allows remote connections via HTTPS'
        }

        xRegistry RC4-1
        {
            Key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 128/128'
            ValueName = 'Enabled'
            ValueData = '0'
            ValueType = 'Dword'
            Ensure = 'Present'
        }

        xRegistry RC4-2
        {
            Key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 40/128'
            ValueName = 'Enabled'
            ValueData = '0'
            ValueType = 'Dword'
            Ensure = 'Present'
        }

        xRegistry RC4-3
        {
            Key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 56/128'
            ValueName = 'Enabled'
            ValueData = '0'
            ValueType = 'Dword'
            Ensure = 'Present'
        }

        xRegistry DisableSSLv3Server
        {
            Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server"
            ValueName = "Enabled"
            Ensure = "Present"
            ValueData = "0"
            ValueType = "Dword"
        }

        xRegistry DisableSSLv3Client
        {
            Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client"
            ValueName = "Enabled"
            Ensure = "Present"
            ValueData = "0"
            ValueType = "Dword"
        }

		File CopySelfSignedCertificateEx
        {
            SourcePath = "$PSScriptRoot\..\modules\New-SelfSignedCertificateEx.psm1"
            DestinationPath = "$($env:PSModulePath.Split(';') -like "*\Program Files\WindowsPowerShell\Modules*" | select -First 1)\New-SelfSignedCertificateEx\New-SelfSignedCertificateEx.psm1"
            Type = 'File'
            Checksum = 'SHA-256'
            Force = $true
            Ensure = 'Present'
        }

		Script SelfSignedCertificate
        {
            TestScript = {
                (Get-ChildItem -Path cert:\LocalMachine\My | Where-Object {$_.Subject -eq "CN=Self Signed Cert"}) -ne $null;
            }
            SetScript = {
				Import-Module New-SelfSignedCertificateEx -Global;
							
				$tokenCert = New-SelfSignedCertificateEx -Subject 'CN=Self Signed Cert' -FriendlyName 'Self Signed Cert' -KeySpec 'Signature' -KeyUsage 'DigitalSignature' -SignatureAlgorithm 'SHA256' -StoreLocation 'LocalMachine' -Exportable -NotAfter ([datetime]::now.AddYears(50));

				$tokenCertPath = Join-Path $env:ProgramData "Microsoft/Crypto/RSA/MachineKeys";
				$tokenCertPath = Join-Path $tokenCertPath $tokenCert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName;

				$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS", "FullControl", "Allow");
				$tokenCertAcl = (Get-Item $tokenCertPath).GetAccessControl("Access");
				$tokenCertAcl.SetAccessRule($accessRule);

				Set-Acl $tokenCertPath $tokenCertAcl;
            }
            GetScript = { return @{} }
        }
	}
}

SetupBox -OutputPath "${env:ProgramFiles(x86)}\WindowsPowerShell\Configuration";
Start-DscConfiguration -Path "${env:ProgramFiles(x86)}\WindowsPowerShell\Configuration" -Wait -Verbose -Force;