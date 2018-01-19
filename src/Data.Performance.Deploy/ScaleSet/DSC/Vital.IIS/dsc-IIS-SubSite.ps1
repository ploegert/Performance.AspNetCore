install-Module -Name xWebAdministration -Repository PSGallery -Force -Confirm:$False

Configuration ConfigureIIS
{
    Param ( [string] $nodeName, 
            [string] $WebDeployPackagePath, 
            [string] $WebSiteName = "TestSite",
            [string] $WebPoolName = "SecurityApiAppPool" )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration

    #Node localhost
    Node $nodeName
    {

        $WebDefaultSite_VirtDirectory = "$env:SystemDrive\inetpub\wwwroot"
        $WebDefaultSite_Name = 'Default Web Site'
        $WebVirtDirectory = "$env:SystemDrive\inetpub\wwwroot\$WebSiteName"
        
        $packageContent = "C:\WindowsAzure\Applications\WebApplication.zip"
        $packageStaging = "C:\WindowsAzure\Applications\WebApplication\"
        
        $CoreSdkInstall_Url = 'https://dot.net/v1/dotnet-install.ps1'
        $CoreHostInstall_Url = "https://aka.ms/dotnetcore-2-windowshosting"
        $CoreHostInstall_Path = "C:\WindowsAzure\Applications\DotNetCore-WindowsHosting.exe"



        WindowsFeature WebServerRole {
            Name   = "Web-Server"
            Ensure = "Present"
        }
        WindowsFeature WebManagementConsole {
            Name   = "Web-Mgmt-Console"
            Ensure = "Present"
        }
        WindowsFeature WebManagementService {
            Name   = "Web-Mgmt-Service"
            Ensure = "Present"
        }
        WindowsFeature ASPNet45 {
            Name   = "Web-Asp-Net45"
            Ensure = "Present"
        }
        WindowsFeature HTTPRedirection {
            Name   = "Web-Http-Redirect"
            Ensure = "Present"
        }
        WindowsFeature CustomLogging {
            Name   = "Web-Custom-Logging"
            Ensure = "Present"
        }
        WindowsFeature LogginTools {
            Name   = "Web-Log-Libraries"
            Ensure = "Present"
        }
        WindowsFeature RequestMonitor {
            Name   = "Web-Request-Monitor"
            Ensure = "Present"
        }
        WindowsFeature Tracing {
            Name   = "Web-Http-Tracing"
            Ensure = "Present"
        }
        WindowsFeature BasicAuthentication {
            Name   = "Web-Basic-Auth"
            Ensure = "Present"
        }
        WindowsFeature WindowsAuthentication {
            Name   = "Web-Windows-Auth"
            Ensure = "Present"
        }
        WindowsFeature ApplicationInitialization {
            Name   = "Web-AppInit"
            Ensure = "Present"
        }

        #Pre-Reqs
        Script InstallNetCoreSDK {
            GetScript  = { @{ Result = "" } }
            TestScript = { $false }
            SetScript  = {
                Write-Verbose -Message ('{0} {1} {2}' -f "[InstallNetCoreSDK]", "Executing CoreDskInstall","is starting execution: Src:==>$($Using:CoreSdkInstall_Url).")
                &([scriptblock]::Create((Invoke-WebRequest -useb $Using:CoreSdkInstall_Url))) #<additional install-script args>
                Write-Verbose -Message ('{0} {1} {2}' -f "[InstallNetCoreSDK]", "Executing msiexec","is done.")
            }
        }

        Script InstallNetCoreHosting {
            GetScript  = { @{ Result = "" } }
            TestScript = { $false }
            SetScript  = {
                #&([scriptblock]::Create((Invoke-WebRequest -useb 'https://dot.net/v1/dotnet-install.ps1'))) #<additional install-script args>
                
                Write-Verbose -Message ('{0} {1} {2}' -f "[InstallNetCoreHosting]", "Downlaoding CoreHostInstall","is starting execution: Src:==>$($Using:CoreHostInstall_Url), Dst:==>$($Using:CoreHostInstall_Path)")
                $WebClient = New-Object -TypeName System.Net.WebClient;
                $WebClient.DownloadFile($($Using:CoreHostInstall_Url, $($Using:CoreHostInstall_Path)));
                Write-Verbose -Message ('{0} {1} {2}' -f "[InstallNetCoreHosting]", "Downlaoding CoreHostInstall","is done.") 

                Write-Verbose -Message ('{0} {1} {2}' -f "[InstallNetCoreHosting]", "Executing msiexec","is starting execution: PkgName==>$($Using:CoreHostInstall_Path)")
                msiexec /package $($Using:CoreHostInstall_Path) /quiet
                Write-Verbose -Message ('{0} {1} {2}' -f "[InstallNetCoreHosting]", "Executing msiexec","is done.")

                Write-Verbose -Message ('{0} {1} {2}' -f "[InstallNetCoreHosting]", "Stopping IIS","...")
                net stop was /y;
                Write-Verbose -Message ('{0} {1} {2}' -f "[InstallNetCoreHosting]", "Stopping IIS","is done.")

                Write-Verbose -Message ('{0} {1} {2}' -f "[InstallNetCoreHosting]", "Starting IIS","...")
                net start w3svc;
                Write-Verbose -Message ('{0} {1} {2}' -f "[InstallNetCoreHosting]", "Starting IIS","is done.")
            }
        }
        

        Script DownloadWebPackage {
            GetScript  = { @{ Result = "" } }
            TestScript = { $false }
            SetScript  = {
                Write-Verbose -Message ('{0} -eq {1}' -f "WebDeployPackagePath",$using:WebDeployPackagePath)
                Write-Verbose -Message ('{0} -eq {1}' -f "packageContent",$using:packageContent)

                Write-Verbose -Message ('{0} {1} {2}' -f "[DownloadWebPackage]", "Downloading WebPackage","...")
                $WebClient = New-Object -TypeName System.Net.WebClient
                $WebClient.DownloadFile($using:WebDeployPackagePath, $using:packageContent)
                Write-Verbose -Message ('{0} {1} {2}' -f "[DownloadWebPackage]", "Downloading WebPackage","is done.")
            }
        }


        Archive ExtractWebZip {
          Ensure = "Present"  
          Path = $packageContent
          Destination = $packageStaging
        } 

        #File WebFolder {
        #  Ensure = "Present"
        #  Type = "Directory"
        #  DestinationPath = $WebVirtDirectory
        #}

        Script StopAppPool {
            TestScript = {
                Import-Module WebAdministration;
                (Get-ChildItem IIS:\AppPools | where Name -EQ $WebPoolName) -EQ $null;
            }
            SetScript  = {
                Import-Module WebAdministration;

                if ((Get-WebAppPoolState $WebPoolName).Value -ne 'Stopped') {
                    Stop-WebAppPool $WebPoolName;
                    $state = (Get-WebAppPoolState $WebPoolName).Value;

                    $counter = 1;
                    do {
                        $state = (Get-WebAppPoolState $WebPoolName).Value;
                        $counter++;
                        Start-Sleep -Milliseconds 500;
                    }
                    while ($state -ne 'Stopped' -and $counter -le 20)
                }
            }
            GetScript  = { return @{} }
        }



        script destinationfoldercleanup {
            testscript = { return -not (test-path $using:WebVirtDirectory) }
            setscript  = {
                #file resource does not delete files. grrrrrrr
                $sourcefiles = get-childitem $using:packageStaging -recurse;
                $destinationfiles = get-childitem $using:WebVirtDirectory -recurse;
                compare-object $sourcefiles $destinationfiles | where sideindicator -eq '=>' | select -expandproperty inputobject | select -expandproperty fullname | sort -descending | remove-item -recurse -force;
            }
            getscript  =	{ return @{} }
        }

        #File DownloadPackage {
        #  Ensure = "Present"
        #  Type = "File"
        #  SourcePath = $WebDeployPackagePath
        #  DestinationPath = $WebVirtDirectory
        #}

		xWebsite DefaultSite  
		{ 
			Name = $WebDefaultSite_Name
			Ensure = 'Present'
			State = 'Started'
			PhysicalPath = $WebDefaultSite_VirtDirectory
			BindingInfo = @(
				MSFT_xWebBindingInformation
				{
					HostName = '*'
					Protocol = 'HTTP'
					Port = 80
				}
				# MSFT_xWebBindingInformation
				# {
				# 	HostName = '*'
				# 	Protocol = 'HTTPS'
				# 	Port = 443
				# 	CertificateThumbprint = $thumbprint
				# 	CertificateStoreName = 'My'
				# }
			)
		}

        # Sub site located under default folder configuration
        #=============================================================
        File Copy {
             SourcePath      = $packageStaging
             DestinationPath = $WebVirtDirectory
             Recurse         = $true
             Type            = 'Directory'
             MatchSource     = $true
             Checksum        = 'SHA-256'
             Force           = $true
             Ensure          = 'Present'
         }

        xWebAppPool SecurityAPIAppPool
        {
            Name                  = $WebPoolName
            State                 = 'Started'
            autoStart             = $true
            enable32BitAppOnWin64 = $true
            managedPipelineMode   = 'Integrated'
            managedRuntimeVersion = 'v4.0'
            startMode             = 'OnDemand'
            identityType          = 'ApplicationPoolIdentity'
            idleTimeout           = (New-TimeSpan -Minutes 0).ToString()
            maxProcesses          = 1
            Ensure                = 'Present'
        }

        xWebApplication SecurityApi
        {
            Name         = $WebSiteName
            Website      = 'Default Web Site'
            WebAppPool   = $WebPoolName
            PhysicalPath = $WebVirtDirectory
            Ensure       = 'Present'
        }

    }
}

#InstallIIS -OutputPath "${env:ProgramFiles(x86)}\WindowsPowerShell\Configuration";
#Start-DscConfiguration -Path "${env:ProgramFiles(x86)}\WindowsPowerShell\Configuration" -Wait -Verbose -Force;