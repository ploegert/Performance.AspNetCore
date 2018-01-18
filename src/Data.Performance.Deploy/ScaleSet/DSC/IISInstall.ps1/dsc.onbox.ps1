Configuration InstallIIS
# Configuration Main
{

    #Param ( $WebDeployPackagePath )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration

    Node localhost
    {

        $WebSiteName = "SecurityAPI"
        $WebVirtDirectory = "$env:SystemDrive\inetpub\wwwroot\$WebSiteName"
        $WebPoolName = "SecurityApiAppPool"
        $WebDeployPackagePath = "https://raw.githubusercontent.com/ploegert/Performance.AspNetCore/master/src/Data.Performance.Deploy/ScaleSet/WebDeploy/Data.Performance.AspNetCore2.WebAPI.zip"
        $packageContent = "C:\WindowsAzure\Applications\WebApplication.zip"
        $packageStaging = "C:\WindowsAzure\Applications\WebApplication\"
        
        $CoreSdkInstall_Url = 'https://dot.net/v1/dotnet-install.ps1'
        $CoreHostInstall_Url = "https://aka.ms/dotnetcore-2-windowshosting"
        $CoreHostInstall_Path = "C:\WindowsAzure\Applications\DotNetCore-WindowsHosting.exe"


        #Pre-Reqs
        Script InstallNetCoreSDK {
            GetScript  = { @{ Result = "" } }
            TestScript = { $false }
            SetScript  = {
                &([scriptblock]::Create((Invoke-WebRequest -useb $Using:CoreSdkInstall_Url))) #<additional install-script args>
            }
        }

        Script InstallNetCoreHosting {
            GetScript  = { @{ Result = "" } }
            TestScript = { $false }
            SetScript  = {
                #&([scriptblock]::Create((Invoke-WebRequest -useb 'https://dot.net/v1/dotnet-install.ps1'))) #<additional install-script args>
                
                $WebClient = New-Object -TypeName System.Net.WebClient
                $WebClient.DownloadFile($Using:CoreHostInstall_Url, $Using:CoreHostInstall_Path)

                msiexec /package $pkg /quiet

                net stop was /y;
                net start w3svc;
            }
        }
        

        Script DownloadWebPackage {
            GetScript  = { @{ Result = "" } }
            TestScript = { $false }
            SetScript  = {
                Write-Verbose -Message ('{0} -eq {1}' -f "WebDeployPackagePath",$using:WebDeployPackagePath)
                Write-Verbose -Message ('{0} -eq {1}' -f "packageContent",$using:packageContent)

                $WebClient = New-Object -TypeName System.Net.WebClient
                $WebClient.DownloadFile($using:WebDeployPackagePath, $using:packageContent)
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
            Name                  = 'SecurityApiAppPool'
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
            Name         = 'SecurityAPI'
            Website      = 'Default Web Site'
            WebAppPool   = 'SecurityApiAppPool'
            PhysicalPath = $WebVirtDirectory
            Ensure       = 'Present'
        }

    }
}

InstallIIS -OutputPath "${env:ProgramFiles(x86)}\WindowsPowerShell\Configuration";
Start-DscConfiguration -Path "${env:ProgramFiles(x86)}\WindowsPowerShell\Configuration" -Wait -Verbose -Force;