param(
	# $env,
	# $app,
	# $role,
	# $rg
)

#Write-Host "ENV: $env`nAPP: $app`nROLE: $role"

# if ((-not $env) -or (-not $app) -or (-not $role))
# 	{ Write-Host "You are missing parameters!!!" -foregroundcolor Red; break }


function set-sub($env)
{
    write-log "Adding Modules:"
    if (-not(Get-Module Azure)) { import-module azure; write-log "Importing Azure Module" }
    #if (-not(Get-Module AzureRM)) { import-module AzureRM; write-log "Importing AzureRM Module" }
        
	write-log "Setting Subscription to $env"
	switch($env) {
	 dev { $SubName = "be-dev" };
	 d { $SubName = "be-dev" };
	 msdn { $SubName = "be-dev-msdn" };
	 m { $SubName = "be-dev-msdn" };
	 uat { $SubName = "be-uat" };
	 u { $SubName = "be-uat" };
	 prod { $SubName = "be-prod" };
	 p { $SubName = "be-prod" };
	 devops { $SubName = "be-devops" };
	}

	Select-AzureRmSubscription -SubscriptionName $SubName

}

function Write-Log
{
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [AllowEmptyString()]
        [string]
        $Message
    )

    Write-Verbose -Verbose ("[{0:s}] {1}`r`n" -f (get-date), $Message)
}



Function Do-AzureDeployRG
{
	Param(
	[string] $ResourceGroupLocation,
	[string] $ResourceGroupName,
	[switch] $UploadArtifacts,
	[string] $StorageAccountName, 
	[string] $StorageContainerName = $ResourceGroupName.ToLowerInvariant() + '-stageartifacts',
	[string] $TemplateFile,
	[string] $TemplateParametersFile,
	[string] $ArtifactStagingDirectory = '..\bin\Debug\Artifacts',
	[string] $AzCopyPath = '..\Tools\AzCopy.exe'
	)
	
	if(-not ($ResourceGroupLocation))
		{ write-host "ResourceGroupLocation: $ResourceGroupLocation Does not exist. Exiting."; break }
	
	if(-not ($ResourceGroupName))
		{ write-host "ResourceGroupName: $ResourceGroupName Does not exist. Exiting."; break }
	
	if(-not (Test-Path $TemplateFile))
		{ write-host "Template Path of: $TemplateFile Does not exist. Exiting."; break }
	
	if(-not (Test-Path $TemplateParametersFile))
		{ write-host "Template Paramter file Path of: $TemplateParametersFile Does not exist. Exiting."; break }
	
	Set-StrictMode -Version 3
	Import-Module Azure -ErrorAction SilentlyContinue
	
	try {
		$AzureToolsUserAgentString = New-Object -TypeName System.Net.Http.Headers.ProductInfoHeaderValue -ArgumentList 'VSAzureTools', '1.4'
		[Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.UserAgents.Add($AzureToolsUserAgentString)
	} catch { }
	
	$OptionalParameters = New-Object -TypeName Hashtable
	$TemplateFile = [System.IO.Path]::Combine($PSScriptRoot, $TemplateFile)
	$TemplateParametersFile = [System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile)
	
	Write-Host "ResourceGroupName: $ResourceGroupName" -ForegroundColor cyan
	Write-Host "ResourceGroupLocation: $ResourceGroupLocation" -ForegroundColor cyan
	Write-Host "TemplateParametersFile: $TemplateParametersFile" -ForegroundColor cyan
	Write-Host "TemplateFile: $TemplateFile" -ForegroundColor cyan
	$OptionalParameters | out-string
	
	
	# Create or update the resource group using the specified template file and template parameters file
	#Switch-AzureMode AzureResourceManager

	write-host "Resource Group Name: $ResourceGroupName"
	New-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -force

	New-AzureRmResourceGroupDeployment  -ResourceGroupName $ResourceGroupName `
										-TemplateFile $TemplateFile `
										-TemplateParameterFile $TemplateParametersFile `
										@OptionalParameters `
										-Force -Verbose
	
	
}



#==========================================================================================
#==========================================================================================
$sub = "msdn"
$env = "l"
$role ="iot"
$app = "mem"

set-sub $sub



############################ CORE 2.0 #######################################
$dev = @{
	'ResourceGroupName'= "datad-vmss-core2-rg";
	'ResourceGroupLocation' ="East US 2"
	'TemplateFile'=".\scaleset.json";
	'TemplateParametersFile'= ".\scaleset-core2.json";
}


$vars = $dev
$vars | out-string

if((Test-Path ($vars.TemplateFile)) -and (Test-Path ($vars.TemplateParametersFile)))
{ 
	#. ./deploy.ps1 @vars
	Do-AzureDeployRG @vars
}
else
	{ throw "Rutrow scrappy. Your file paths do not exist. `nTemplate:$($vars.TemplateFile) `nParmFile:$($vars.TemplateParametersFile) "}


break

############################ CORE 1.1 #######################################	
$dev = @{
	'ResourceGroupName'= "datad-vmss-core11-rg";
	'ResourceGroupLocation' ="East US 2"
	'TemplateFile'=".\scaleset.json";
	'TemplateParametersFile'= ".\scaleset-core11.json";
}


$vars = $dev
$vars | out-string

if((Test-Path ($vars.TemplateFile)) -and (Test-Path ($vars.TemplateParametersFile)))
{ 
	#. ./deploy.ps1 @vars
	Do-AzureDeployRG @vars
}
else
	{ throw "Rutrow scrappy. Your file paths do not exist. `nTemplate:$($vars.TemplateFile) `nParmFile:$($vars.TemplateParametersFile) "}


############################ CORE netfx #######################################	
$dev = @{
	'ResourceGroupName'= "datad-vmss-core461-rg";
	'ResourceGroupLocation' ="East US 2"
	'TemplateFile'=".\scaleset.json";
	'TemplateParametersFile'= ".\scaleset-core461.json";
}


$vars = $dev
$vars | out-string

if((Test-Path ($vars.TemplateFile)) -and (Test-Path ($vars.TemplateParametersFile)))
{ 
	#. ./deploy.ps1 @vars
	Do-AzureDeployRG @vars
}
else
	{ throw "Rutrow scrappy. Your file paths do not exist. `nTemplate:$($vars.TemplateFile) `nParmFile:$($vars.TemplateParametersFile) "}







# UpdateEnvSetting "ServiceStoreAccountName" $storageAccount.StorageAccountName
# UpdateEnvSetting "ServiceStoreAccountConnectionString" $result.Outputs['storageConnectionString'].Value
# UpdateEnvSetting "ServiceSBName" $sevicebusName
# UpdateEnvSetting "ServiceSBConnectionString" $result.Outputs['ehConnectionString'].Value
# UpdateEnvSetting "ServiceEHName" $result.Outputs['ehOutName'].Value
# UpdateEnvSetting "IotHubName" $result.Outputs['iotHubHostName'].Value
# UpdateEnvSetting "IotHubConnectionString" $result.Outputs['iotHubConnectionString'].Value
# UpdateEnvSetting "DocDbEndPoint" $result.Outputs['docDbURI'].Value
# UpdateEnvSetting "DocDBKey" $result.Outputs['docDbKey'].Value
# UpdateEnvSetting "DeviceTableName" "DeviceList"
# UpdateEnvSetting "RulesEventHubName" $result.Outputs['ehRuleName'].Value
# UpdateEnvSetting "RulesEventHubConnectionString" $result.Outputs['ehConnectionString'].Value


# $vars = @{
# 			'ResourceGroupName'= "memd-demoadx-rg";
# 			'ResourceGroupLocation' ="East US 2"
# 			'TemplateFile'=".\mem\mem-box.json";
# 			'TemplateParametersFile'= ".\mem\mem-demo.adx.param.msdn.json";
# }

# if((Test-Path ($vars.TemplateFile)) -and (Test-Path ($vars.TemplateParametersFile)))
# 	{ Do-AzureDeployRG @vars}
# else
# 	{ throw "Rutrow scrappy. Your file paths do not exist. `nTemplate:$($vars.TemplateFile) `nParmFile:$($vars.TemplateParametersFile) "}


# $vars = @{
# 			'ResourceGroupName'= "memd-demonae-rg";
# 			'ResourceGroupLocation' ="East US 2"
# 			'TemplateFile'=".\mem\mem-box.json";
# 			'TemplateParametersFile'= ".\mem\mem-demo.nae.param.msdn.json";
# }

# if((Test-Path ($vars.TemplateFile)) -and (Test-Path ($vars.TemplateParametersFile)))
# 	{ Do-AzureDeployRG @vars}
# else
# 	{ throw "Rutrow scrappy. Your file paths do not exist. `nTemplate:$($vars.TemplateFile) `nParmFile:$($vars.TemplateParametersFile) "}
















#(Get-AzureResourceGroupLog -ResourceGroup $ResourceGroupName -DetailedOutput)[0]

#New-AzureResourceGroup -Name eisdev-delete -Location "Central US" -TemplateFile "..\Templates\newnet\v2network.json" -TemplateParameterFile "..\Templates\newnet\v2net.dev.json"  
#Test-AzureResourceGroupTemplate -ResourceGroupName eisdev-delete -Location "Central US" -TemplateFile "..\Templates\newnet\v2network.json" -TemplateParameterFile "..\Templates\newnet\v2net.dev.json"  


#Test-AzureResourceGroupTemplate -ResourceGroupName eisdev-delete -TemplateFile "..\Templates\eis-net.json" -TemplateParameterFile "..\Templates\eis-net.param.dev.json"  


