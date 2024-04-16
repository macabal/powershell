Function migrateCMGContent () {
    [CmdletBinding()]
    param (
        [string] $SiteCode,
        [string] $DPSource,
        [string] $DPDestination
    ) 
    $allContentCMG = Get-WmiObject -ComputerName localhost -Namespace "root/SMS/site_$siteCode" -Query "SELECT * FROM SMS_DPContentInfo" | Where-Object NALPath -like "*$DPSource*"

    foreach ($content in $allContentCMG) {
    Write-Host "Proccesing $($content.PackageID) - $($content.Name) ---- ObjectType: $($content.objectType)"
        if ($content.objectType -eq 512) { 
            Write-Host "Application: Distributing $($content.PackageID) - $($content.Name) to $DPDestination"
            try { Start-CMContentDistribution -ApplicationName $content.Name -DistributionPointName $dpname -ErrorAction Continue }
            catch [System.InvalidOperationException] { Write-Host "Content has already been distributed to the specified destination" -ForegroundColor Red }          
        }
        if ($content.ObjectType -eq 5) {
            Write-Host "Deployment Package: Distributing $($content.PackageID) - $($content.Name) to $DPDestination"  
            try { Start-CMContentDistribution -DeploymentPackageId $content.PackageID -DistributionPointName $dpname -ErrorAction Continue  }
            catch [System.InvalidOperationException] { Write-Host "Content has already been distributed to the specified destination" -ForegroundColor Red }            
       }
        if ($content.objectType -eq 0) { 
            Write-Host "Package: Distributing $($content.PackageID) - $($content.Name) to $DPDestination"
            try { Start-CMContentDistribution -PackageName $content.Name -DistributionPointName $dpname -ErrorAction Continue }
            catch [System.InvalidOperationException] { Write-Host "Content has already been distributed to the specified destination" -ForegroundColor Red }  
        }
        if ($content.objectType -eq 3) { 
            Write-Host "Driver: Distributing $($content.PackageID) - $($content.Name) to $DPDestination"
            try { Start-CMContentDistribution -PackageName $content.Name -DistributionPointName $dpname -ErrorAction Continue }
            catch [System.InvalidOperationException] { Write-Host "Content has already been distributed to the specified destination" -ForegroundColor Red }  
        }
        if ($content.objectType -eq 258) { 
            Write-Host "BootImage: Distributing $($content.PackageID) - $($content.Name) to $DPDestination"
            try { Start-CMContentDistribution -PackageName $content.Name -DistributionPointName $dpname -ErrorAction Continue }
            catch [System.InvalidOperationException] { Write-Host "Content has already been distributed to the specified destination" -ForegroundColor Red }  
        }
        if ($content.objectType -eq 259) { 
            Write-Host "OSImage: Distributing $($content.PackageID) - $($content.Name) to $DPDestination"
            try { Start-CMContentDistribution -PackageName $content.Name -DistributionPointName $dpname -ErrorAction Continue }
            catch [System.InvalidOperationException] { Write-Host "Content has already been distributed to the specified destination" -ForegroundColor Red }  
        }
        if ($content.objectType -eq 257) { 
            Write-Host "WIM Image: Distributing $($content.PackageID) - $($content.Name) to $DPDestination"
            try { Start-CMContentDistribution -PackageName $content.Name -DistributionPointName $dpname -ErrorAction Continue }
            catch [System.InvalidOperationException] { Write-Host "Content has already been distributed to the specified destination" -ForegroundColor Red }  
        }
    }
}



migrateCMGContent -SiteCode "GUR" -DPSource "CNTAISVR013.GURIT.COM" -DPDestination "CNTAISVR015.GURIT.COM"