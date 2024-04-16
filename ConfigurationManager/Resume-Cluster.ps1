## variables
$logFolder = "C:\Windows\CCM\Logs\Apps"
$appName = "OG_RESUME-CLUSTER_POST-SCRIPT"
$computer = $env:COMPUTERNAME

## Functions
function Get-TimeStamp {
    return "[{0:MM/dd/yyyy} {0:HH:mm:ss}]" -f (Get-Date)
}

# Create log folder
If (-Not (Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder
}

# Start logging
Start-Transcript "$logFolder\$appName.log" -Append

Write-Host "$(Get-TimeStamp) Orchestation post-script starting."
Write-Host "$(Get-TimeStamp) Current node is: $($computer)"

## Current workload distribution before resuming
$allClusterResources = Get-ClusterResource | Select-Object Cluster, Name, resourcetype, ownergroup, ownernode | ft
Write-Host "--------------------------------------------------------------------------------------------------------"
Get-ClusterResource | Select-Object Cluster, Name, resourcetype, ownergroup, ownernode | ft
Write-Host "--------------------------------------------------------------------------------------------------------"

# Resume cluster and inmediately brings back the workloads drained from the nodes
Write-Host "$(Get-TimeStamp) Starting resume command on: $($computer)"
Do {
    Resume-ClusterNode -Name $computer -Failback Immediate
    Write-Host "$(Get-TimeStamp) Current node resume status is: " -NoNewline
    Write-Host (Get-ClusterNode –Name $computer).State 
    Sleep -Seconds 5
} while ((Get-ClusterNode –Name $computer).State -ne "Up")

## Current workload distribution after suspending
Write-Host "--------------------------------------------------------------------------------------------------------"
Get-ClusterResource | Select-Object Cluster, Name, resourcetype, ownergroup, ownernode | ft
Write-Host "--------------------------------------------------------------------------------------------------------"

Sleep -Seconds 3

if ((Get-ClusterNode –Name $computer).State -ne "Up") {
    Write-Host "$(Get-TimeStamp) Current node resume status is COMPLETED"
    Sleep -Seconds 3
    Write-Host "$(Get-TimeStamp) Orchestation post-script finish. Exit code 0."
    Stop-Transcript
    #Exit 0
}else {
    Write-Host "$(Get-TimeStamp) Current node resume status is: " -NoNewline
    Write-Host (Get-ClusterNode –Name $computer).State
    Write-Host "$(Get-TimeStamp) We cannot continue because current state is not correct"
    Write-Host "$(Get-TimeStamp) Orchestation post-script finish. Exit code 1."
    Stop-Transcript
    #Exit 1
}