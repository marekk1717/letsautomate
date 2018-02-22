Write-Host "Commserve Silent Installation..."
$job = Start-Job -Name "Job1" -ScriptBlock {Start-Process -Wait -NoNewWindow -FilePath "cmd.exe" -WorkingDirectory "C:\Program Files\Commvault\installer" -ArgumentList "/c start /wait setup.exe /play install.xml"}
$logfile = "F:\Program Files\Commvault\Contentstore\Log Files\Install.log"
while (!(Test-Path $logfile -PathType leaf)) { Start-Sleep 5 }
Start-Job -Name "Job2" -ScriptBlock {Get-Content $logfile -Wait}
while (($job.State -eq "Running") -and ($job.State -ne "NotStarted"))
{
    Start-Sleep -Seconds 1
    Receive-Job -Name "Job2"
}
Start-Sleep -Seconds 20
Stop-Job -Name "Job2"
Write-Host "Qlogin"
Start-Process -Wait -WindowStyle Hidden -FilePath "qlogin.exe" -WorkingDirectory "F:\Program Files\Commvault\Contentstore\Base" -ArgumentList "-u admin -p"
Write-Host "Configuration of Azure Cloud Library..."
Start-Process -Wait -WindowStyle Hidden -FilePath "qoperation.exe" -WorkingDirectory "F:\Program Files\Commvault\Contentstore\Base" -ArgumentList "execute -af C:\CVINSTALL\cloudlib.xml"
Write-Host "Configuration of Global Deduplication Policy..."
Start-Process -Wait -WindowStyle Hidden -FilePath "qoperation.exe" -WorkingDirectory "F:\Program Files\Commvault\Contentstore\Base" -ArgumentList "execute -af C:\CVINSTALL\SP_creation.xml -storagePolicyName SP_GDSP1 -libraryName AzureCloudLib -mediaAgentName $env:computername -maInfoList/mediaAgent/mediaAgentName $env:computername -path G:\DDB1 -enableGlobalDeduplication 1 -hostGlobalDedupStore 1 -enableDASHFull 1 -enableDeduplication 1 -encryptData 1 -encryptionType AES -encryptionKeyLength 256"
Write-Host "Configuration of Storage Policy..."
Start-Process -Wait -WindowStyle Hidden -FilePath "qoperation.exe" -WorkingDirectory "F:\Program Files\Commvault\Contentstore\Base" -ArgumentList "execute -af C:\CVINSTALL\SP_creation.xml -storagePolicyName SP1 -useglobalpolicy/storagePolicyName SP_GDSP1 -enableDeduplication 1 -useGlobalDedupStore 1 -enableDASHFull 1 -enableClientSideDedup 1 -retainBackupDataForCycles 4 -retainBackupDataForDays 30"
If(Test-Path C:\CVINSTALL\azurerm.xml -PathType leaf) {
Write-Host "Configuration of Azure VSA client..."
Start-Process -Wait -WindowStyle Hidden -FilePath "qoperation.exe" -WorkingDirectory "F:\Program Files\Commvault\Contentstore\Base" -ArgumentList "execute -af C:\CVINSTALL\azurerm.xml"
Write-Host "Configuration of Schedule Policy"
Start-Process -Wait -WindowStyle Hidden -FilePath "qoperation.exe" -WorkingDirectory "F:\Program Files\Commvault\Contentstore\Base" -ArgumentList "execute -af C:\CVINSTALL\schedule.xml"
Start-Process -Wait -WindowStyle Hidden -FilePath "qoperation.exe" -WorkingDirectory "F:\Program Files\Commvault\Contentstore\Base" -ArgumentList "execute -af C:\CVINSTALL\create_subclient_template.xml -appName `"Virtual Server`" -clientName AzureRM -instanceName `"Azure Resource Manager`" -backupsetName defaultBackupSet -subclientName `"$region`" -vmContent/children/displayName `"$region`" -vmContent/children/name westeurope -vmContent/children/type DATACENTER -storagePolicyName SP1 -useChangedTrackingOnVM True"
}
Write-Host "Qlogout"
Start-Process -Wait -WindowStyle Hidden -FilePath "qlogout.exe" -WorkingDirectory "F:\Program Files\Commvault\Contentstore\Base"
