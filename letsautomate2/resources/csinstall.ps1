param (
    [string]$saccount = "storageaccount", 
    [string]$saccountkey = "XXXXXXXX"
)

Import-Module BitsTransfer
If(!(test-path C:\CVINSTALL)) { New-Item -ItemType directory -Path C:\CVINSTALL }
Get-Disk | Where-Object partitionstyle -eq 'raw' | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -Confirm:$false
If(!(test-path G:\DDB1)) { New-Item -ItemType directory -Path G:\DDB1 }
Start-BitsTransfer -Source "http://downloadcenter.commvault.com/CVDownloadCenter/11.0/build80/Bootstrappers/SP10/Commvault_R80_SP10_26January18.exe?__cv__=1522757529_9f2aa0796cdbee5c4e45410b6ca82172&ext=.exe" -Destination "C:\CVINSTALL\CommvaultSetup.exe"
Start-Process -Wait -FilePath C:\CVINSTALL\CommvaultSetup.exe -ArgumentList '/s /noinstall'
Start-BitsTransfer -Source "http://documentation.commvault.com/commvault/v11/others/features/storage_policies/xml/SP_creation.xml" -Destination "C:\CVINSTALL\SP_creation.xml"
Start-BitsTransfer -Source "https://raw.githubusercontent.com/marekk1717/letsautomate/master/letsautomate2/resources/install.xml" -Destination "C:\Program Files\Commvault\installer\install.xml"
Start-BitsTransfer -Source "https://raw.githubusercontent.com/marekk1717/letsautomate/master/letsautomate2/resources/cloudlib.tmp" -Destination "C:\CVINSTALL\cloudlib.tmp"
Start-Process -Wait -NoNewWindow -FilePath "cmd.exe" -WorkingDirectory "C:\Program Files\Commvault\installer" -ArgumentList "/c start /wait setup.exe /play install.xml"
Start-Sleep -Seconds 60

(Get-Content "C:\CVINSTALL\cloudlib.tmp")  -replace "storage_account",$saccount  -replace "storage_primary_key", $saccountkey -replace "vmname",$env:computername | Set-Content "C:\CVINSTALL\cloudlib.xml"

Start-Process -Wait -FilePath "qlogin.exe" -WorkingDirectory "F:\Program Files\Commvault\Contentstore\Base" -ArgumentList "-u admin -p"
Start-Process -Wait -FilePath "qoperation.exe" -WorkingDirectory "F:\Program Files\Commvault\Contentstore\Base" -ArgumentList "execute -af C:\CVINSTALL\cloudlib.xml"
Start-Process -Wait -FilePath "qoperation.exe" -WorkingDirectory "F:\Program Files\Commvault\Contentstore\Base" -ArgumentList "execute -af C:\CVINSTALL\SP_creation.xml -storagePolicyName SP_GDSP1 -libraryName AzureCloudLib -mediaAgentName $env:computername -maInfoList/mediaAgent/mediaAgentName $env:computername -path G:\DDB1 -enableGlobalDeduplication 1 -hostGlobalDedupStore 1 -enableDASHFull 1 -enableDeduplication 1 -encryptData 1 -encryptionType AES -encryptionKeyLength 256"
Start-Process -Wait -FilePath "qoperation.exe" -WorkingDirectory "F:\Program Files\Commvault\Contentstore\Base" -ArgumentList "execute -af C:\CVINSTALL\SP_creation.xml -storagePolicyName SP1 -useglobalpolicy/storagePolicyName SP_GDSP1 -enableDeduplication 1 -useGlobalDedupStore 1 -enableDASHFull 1 -enableClientSideDedup 1 -retainBackupDataForCycles 4 -retainBackupDataForDays 30"
Start-Process -Wait -FilePath "qlogout.exe" -WorkingDirectory "F:\Program Files\Commvault\Contentstore\Base"
