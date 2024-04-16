## variables
$logFolder = "C:\Windows\CCM\Logs\Apps"
$appName = "OG_SUSPEND-CLUSTER_PRE-SCRIPT"
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

Write-Host "$(Get-TimeStamp) Orchestation pre-script starting."
Write-Host "$(Get-TimeStamp) Current node is: $($computer)"

## Current workload  distribution before suspending
Write-Host "--------------------------------------------------------------------------------------------------------"
Get-ClusterResource | Select-Object Cluster, Name, resourcetype, ownergroup, ownernode | ft
Write-Host "--------------------------------------------------------------------------------------------------------"

#Find other nodes from the same cluster
Write-Host "$(Get-TimeStamp) Searching for other nodes in Cluster"
$otherNodes = Get-ClusterNode | Where-Object { $_.Name -ne $computer -and $_.State -eq "Up" }
Write-Host "$(Get-TimeStamp) Found $($otherNodes.count) more nodes"

#If only one result, we will select the additional node
#if more results, we will select the first one
Write-Host "$(Get-TimeStamp) Choosing node to assign workloads"
if ($otherNodes.count -gt 1) {
    $selectedNode = $otherNodes | Select-Object -First 1
}else {
    $selectedNode = $otherNodes
}
Write-Host "$(Get-TimeStamp) The selected node is: $($selectedNode.Name)"

#We pause this node and move its workloads to the selected node
#Drain parameter: Clustered roles running on the node will be drained before the node is paused
#ForceDrain parameter: Any workload failed will be stopped and move. Pause will be forced
#Wait parameter: to wait for completion
Write-Host "$(Get-TimeStamp) Starting suspension of current node"
Suspend-ClusterNode -Name $computer -TargetNode $selectedNode.Name -Drain -ForceDrain -Wait

##We check if drainstatus is completed
Do
{
    Write-Host "$(Get-TimeStamp) Current node drain status is: " -NoNewline
    Write-Host (Get-ClusterNode –Name $computer).DrainStatus  
    Sleep -Seconds 5
}
until ((Get-ClusterNode –Name $computer).DrainStatus -ne "InProgress")

## Current workload distribution after suspending
Write-Host "--------------------------------------------------------------------------------------------------------"
Get-ClusterResource | Select-Object Cluster, Name, resourcetype, ownergroup, ownernode | ft
Write-Host "--------------------------------------------------------------------------------------------------------"

Start-Sleep -Seconds 3

If ((Get-ClusterNode –Name $computer).DrainStatus -eq "Completed" -and (((Get-ClusterNode –Name $computer).State -eq "Paused") -or (Get-ClusterNode –Name $computer).State -eq "Suspended"))
{
    Write-Host "$(Get-TimeStamp) Current node drain status is COMPLETED"
    Sleep -Seconds 3
    Write-Host "$(Get-TimeStamp) Orchestation pre-script finish. Exit code 0"
    Stop-Transcript
    #Exit 0
}else {
    Write-Host "$(Get-TimeStamp) Current node drain status is: " -NoNewline
    Write-Host (Get-ClusterNode –Name $computer).DrainStatus
    Write-Host "$(Get-TimeStamp) We cannot continue because drainstatus is not completed"
    Write-Host "$(Get-TimeStamp) Orchestation pre-script finish. Exit code 1"
    Stop-Transcript
    #Exit 1
}