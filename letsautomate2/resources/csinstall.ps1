param (
    [string]$saccount = "storageaccount", 
    [string]$saccountkey = "XXXX",
    [string]$adminuser = "adminuser",
    [string]$app_id = "XXXX",
    [string]$app_pwd = "XXXX",
    [string]$subscription_id = "XXXX",
    [string]$tenant_id = "XXXX"
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
Start-BitsTransfer -Source "https://raw.githubusercontent.com/marekk1717/letsautomate/master/letsautomate2/resources/installcs.ps1" -Destination "C:\Users\$adminuser\installcs.ps1"
Start-BitsTransfer -Source "https://raw.githubusercontent.com/marekk1717/letsautomate/master/letsautomate2/resources/azurerm.tmp" -Destination "C:\CVINSTALL\azurerm.tmp"
(Get-Content "C:\CVINSTALL\cloudlib.tmp")  -replace "storage_account",$saccount  -replace "storage_primary_key", $saccountkey -replace "vmname",$env:computername | Set-Content "C:\CVINSTALL\cloudlib.xml"
