<#
.SYNOPSIS 
Change OS requirements in deployment types. Useful for adding Windows 11 as a requirement.
.DESCRIPTION
Single or bulk OS requirement set or update for Windows 10, Windows 11 or both (configure this using $osrequired variable)
Script will connect to SCCM, create requirement as configured and foreach application you selected it will remove the existing requirements and add the ones chosen
#>

## Configure all needed variables
$SiteCode = "" # Site code 
$ProviderMachineName = "" # SMS Provider machine name
[Int32]$osRequired = 2 # 1 = Windows 10; 2 = Windows 11; 3 = both Windows 10 and Windows 11

$allApps = "SW - Net Framework 3.5" ## Choose single application
$allApps = Get-WmiObject -ComputerName localhost -Namespace "root\SMS\site_$sitecode" -Class SMS_Applicationlatest | Where-Object {$_.ObjectPath -eq "/01__ PRODUCTION SOFTWARE"} ## Choose applications in a SCCM folder
$allApps = Get-CMApplication ## Get all applications or filter as needed
#################################

# Connect to SCCM
$initParams = @{}
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}
Set-Location "$($SiteCode):\" @initParams
######################################


## Prepare OS requirement for deployment type
$globalCondition = Get-CMGlobalCondition -Name "Operating System" | Where-Object PlatformType -eq 1
if ($osRequired -eq 1) {
    $Windows10 = Get-CMConfigurationPlatform -Fast | Where-Object ModelName -eq "Windows/All_x64_Windows_10_and_higher_Clients"
    $osRequirement = $globalCondition | New-CMRequirementRuleOperatingSystemValue -RuleOperator OneOf -Platform $Windows10
    Write-Host "---------- Created W10 requirement!" -ForegroundColor Magenta
}elseif ($osRequired -eq 2) {
    $Windows11 = Get-CMConfigurationPlatform -Fast | Where-Object ModelName -eq "Windows/All_x64_Windows_11_and_higher_Clients"
    $osRequirement = $globalCondition | New-CMRequirementRuleOperatingSystemValue -RuleOperator OneOf -Platform $Windows11
    Write-Host "---------- Created W11 requirement!" -ForegroundColor Magenta
}elseif ($osRequired -eq 3) {
    $Windows10 = Get-CMConfigurationPlatform -Fast | Where-Object ModelName -eq "Windows/All_x64_Windows_10_and_higher_Clients"
    $Windows11 = Get-CMConfigurationPlatform -Fast | Where-Object ModelName -eq "Windows/All_x64_Windows_11_and_higher_Clients"
    $osRequirement = $globalCondition | New-CMRequirementRuleOperatingSystemValue -RuleOperator OneOf -Platform $Windows10, $Windows11
    Write-Host "---------- Created W10 and W11 requirement!" -ForegroundColor Magenta
}

## Delete requirements if exists and add the created ones
foreach ($application in $allApps)
{
    $app = Get-CMApplication -Name $application
    Write-Host "Checking application $($app.LocalizedDisplayName)" -ForegroundColor Magenta
    $allDeploymentTypes = Get-CMDeploymentType -ApplicationName $app.LocalizedDisplayName
    Foreach ($dt in $allDeploymentTypes){
        $requirements =  $dt | Get-CMDeploymentTypeRequirement
        if ($null -ne $requirements) {
            foreach ($req in $requirements) {
                Write-Host "Deleting $($req.Name)" -ForegroundColor Yellow
                Set-CMDeploymentType -RemoveRequirement $req -DeploymentTypeName $dt.LocalizedDisplayName -ApplicationName $app.LocalizedDisplayName
            }
        }
        Write-Host "Adding $($osRequirement.Name)" -ForegroundColor Green
        Set-CMDeploymentType -AddRequirement $osRequirement -DeploymentTypeName $dt.LocalizedDisplayName -ApplicationName $app.LocalizedDisplayName
    } 
}