Configuration SetupDefaultWebsite
{   
	Import-DscResource -ModuleName PSDesiredStateConfiguration;
	Import-DSCResource -ModuleName xWebAdministration;

	Node localhost
	{
        Import-Module WebAdministration;


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



        $binding = Get-ChildItem IIS:SSLBindings | where Port -EQ 443 | where Sites -EQ 'Default Web Site';
        $thumbprint = if ($binding -EQ $null)
        {
            (Get-ChildItem -Path cert:\LocalMachine\My | where {$_.Subject -eq 'CN=Self Signed Cert'}).Thumbprint;
        }
        else
        {
            $binding.Thumbprint;
        }
                
		xWebsite DefaultSite  
		{ 
			Name = 'Default Web Site'
			Ensure = 'Present'
			State = 'Started'
			PhysicalPath = "$env:SystemDrive\inetpub\wwwroot"
			BindingInfo = @(
				MSFT_xWebBindingInformation
				{
					HostName = '*'
					Protocol = 'HTTP'
					Port = 80
				}
				MSFT_xWebBindingInformation
				{
					HostName = '*'
					Protocol = 'HTTPS'
					Port = 443
					CertificateThumbprint = $thumbprint
					CertificateStoreName = 'My'
				}
			)
		}
	}
}

SetupDefaultWebsite -OutputPath "${env:ProgramFiles(x86)}\WindowsPowerShell\Configuration";
Start-DscConfiguration -Path "${env:ProgramFiles(x86)}\WindowsPowerShell\Configuration" -Wait -Verbose -Force;