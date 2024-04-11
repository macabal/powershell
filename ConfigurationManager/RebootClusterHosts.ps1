param (
[Parameter(Mandatory=$true)][string]$ClusterName
)

$VerbosePreference = "continue"

Write-Host "Cluster [$ClusterName]"

$Nodes = (Get-ClusterNode –Cluster $ClusterName)

foreach ($Node in $Nodes) {
    if ($Node.State -eq "Up") {
        $TimeStamp = Get-Date -Format "dd.MMM.yyyy HH:mm:ss"
        Write-Host "$TimeStamp - Pausing Host [$Node] and draining roles"
    
        Suspend-ClusterNode -Name $Node.Name -Cluster $ClusterName -Drain -Wait

        Start-Sleep -s 5

        $NodeStatus = Get-ClusterNode -Cluster $ClusterName -Name $Node.Name
        
        if (($NodeStatus.DrainStatus -ne "Completed") -or ($NodeStatus.State -ne "Paused")) {
             
             $TimeStamp = Get-Date -Format "dd.MMM.yyyy HH:mm:ss"
             Write-Host "$TimeStamp - Looks like there was some issue draining and pausing the Host [$Node]"
             $TimeStamp = Get-Date -Format "dd.MMM.yyyy HH:mm:ss"
             Read-Host "$TimeStamp - Please manually pause the Host [$Node] and press [Enter] key to continue, or press [Ctrl-C] to stop the script"
             
             $NodeStatus = Get-ClusterNode -Cluster $ClusterName -Name $Node.Name

             while (($NodeStatus.DrainStatus -ne "Completed") -or ($NodeStatus.State -ne "Paused")) {
             
                 $TimeStamp = Get-Date -Format "dd.MMM.yyyy HH:mm:ss"
                 Write-Host "$TimeStamp - Looks like the Host [$Node] is still not paused"
                 $TimeStamp = Get-Date -Format "dd.MMM.yyyy HH:mm:ss"
                 Read-Host "$TimeStamp - Please manually pause the Host [$Node] and press [Enter] key to continue, or press [Ctrl-C] to stop the script"
             
                 $NodeStatus = Get-ClusterNode -Cluster $ClusterName -Name $Node.Name
             }
        }

        if (($NodeStatus.DrainStatus -eq "Completed") -and ($NodeStatus.State -eq "Paused")) {
            $TimeStamp = Get-Date -Format "dd.MMM.yyyy HH:mm:ss"
            Write-Host "$TimeStamp - Host [$Node] is paused"

            $TimeStamp = Get-Date -Format "dd.MMM.yyyy HH:mm:ss"
            Write-Host "$TimeStamp - Now Rebooting Host [$Node] and waiting for it to come online"
            Restart-Computer -ComputerName $Node.Name -Force -Wait -For PowerShell -Delay 15
        
            $NodeStatus = Get-ClusterNode -Cluster $ClusterName -Name $Node.Name

            $TimeStamp = Get-Date -Format "dd.MMM.yyyy HH:mm:ss"
            Write-Host "$TimeStamp - Host [$Node] is now online"
        
            $TimeStamp = Get-Date -Format "dd.MMM.yyyy HH:mm:ss"
            Write-Host "$TimeStamp - Giving it another 15 seconds to stabilize"

            Start-Sleep -s 15

            Do {
                $NodeStatus = Get-ClusterNode -Cluster $ClusterName -Name $Node.Name
                Start-Sleep -s 1
            } while ($NodeStatus.State -eq "Down")

            $TimeStamp = Get-Date -Format "dd.MMM.yyyy HH:mm:ss"
            Write-Host "$TimeStamp - Resuming Host [$Node]"
        
            Do {
                Resume-ClusterNode -Name $Node.Name -Cluster $ClusterName
                Start-Sleep -s 1
                $NodeStatus = Get-ClusterNode -Cluster $ClusterName -Name $Node.Name
            } while ($NodeStatus.State -ne "Up")
          
            Start-Sleep -s 5

            $TimeStamp = Get-Date -Format "dd.MMM.yyyy HH:mm:ss"
            Write-Host "$TimeStamp - Host [$Node] is now active"
        }
    }
    else {
        $TimeStamp = Get-Date -Format "dd.MMM.yyyy HH:mm:ss"
        Write-Host "$TimeStamp - Host [$Node] is Down! Skipping it"
    }
}