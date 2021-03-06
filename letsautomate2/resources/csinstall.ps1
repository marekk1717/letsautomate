param (
    [string]$saccount = "XXXX", 
    [string]$saccountkey = "XXXX",
    [string]$saccountdr = "XXXX", 
    [string]$saccountkeydr = "XXXX",
    [string]$adminuser = "adminuser",
    [string]$app_id = "XXXX",
    [string]$app_pwd = "XXXX",
    [string]$subscription_id = "XXXX",
    [string]$tenant_id = "XXXX",
    [string]$region = "XXXX"
)

Import-Module BitsTransfer
If(!(test-path C:\CVINSTALL)) { New-Item -ItemType directory -Path C:\CVINSTALL }
Get-Disk | Where-Object partitionstyle -eq 'raw' | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -Confirm:$false
If(!(test-path G:\DDB1)) { New-Item -ItemType directory -Path G:\DDB1 }
Start-BitsTransfer -Source "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
Start-Process -Wait -FilePath C:\CVINSTALL\CommvaultSetup.exe -ArgumentList '/s /noinstall'
Start-BitsTransfer -Source "http://documentation.commvault.com/commvault/v11/others/features/storage_policies/xml/SP_creation.xml" -Destination "C:\CVINSTALL\SP_creation.xml"
Start-BitsTransfer -Source "https://raw.githubusercontent.com/marekk1717/letsautomate/master/letsautomate2/resources/install.xml" -Destination "C:\Program Files\Commvault\installer\install.xml"
Start-BitsTransfer -Source "https://raw.githubusercontent.com/marekk1717/letsautomate/master/letsautomate2/resources/cloudlib.tmp" -Destination "C:\CVINSTALL\cloudlib.tmp"
Start-BitsTransfer -Source "https://raw.githubusercontent.com/marekk1717/letsautomate/master/letsautomate2/resources/installcs.tmp" -Destination "C:\CVINSTALL\installcs.tmp"
Start-BitsTransfer -Source "https://raw.githubusercontent.com/marekk1717/letsautomate/master/letsautomate2/resources/azurerm.tmp" -Destination "C:\CVINSTALL\azurerm.tmp"
Start-BitsTransfer -Source "https://raw.githubusercontent.com/marekk1717/letsautomate/master/letsautomate2/resources/schedule.xml" -Destination "C:\CVINSTALL\schedule.xml"
Start-BitsTransfer -Source "http://documentation.commvault.com/commvault/v11/others/products/vs_vmware/command_line_xml/create_subclient_template.xml" -Destination "C:\CVINSTALL\create_subclient_template.xml"
Start-BitsTransfer -Source "http://documentation.commvault.com/commvault/v11/others/products/vs_vmware/command_line_xml/update_vm_filters_template.xml" -Destination "C:\CVINSTALL\update_vm_filters_template.xml"
Start-BitsTransfer -Source "http://documentation.commvault.com/commvault/v11/others/features/schedule_policy/command_line_xml/schedule_policies_edit.xml" -Destination "C:\CVINSTALL\schedule_policies_edit.xml"
(Get-Content "C:\CVINSTALL\cloudlib.tmp")  -replace "storage_account",$saccount -replace "storage_primary_key", $saccountkey -replace "vmname",$env:computername | Set-Content "C:\CVINSTALL\cloudlib.xml"
(Get-Content "C:\CVINSTALL\installcs.tmp")  -replace "varregion",$region | Set-Content "C:\CVINSTALL\installcs.ps1"
If ($app_id -ne 'XXXX' -And $app_pwd -ne 'XXXX' -And $subscription_id -ne 'XXXX' -And $tenant_id -ne 'XXXX') { (Get-Content "C:\CVINSTALL\azurerm.tmp")  -replace "vmname",$env:computername -replace "subscription_id",$subscription_id -replace "tenant_id",$tenant_id -replace "app_pwd",$app_pwd -replace "app_id",$app_id | Set-Content "C:\CVINSTALL\azurerm.xml" }
Remove-Item -Path C:\CVINSTALL\installcs.tmp -Force
Remove-Item -Path C:\CVINSTALL\cloudlib.tmp -Force
Remove-Item -Path C:\CVINSTALL\azurerm.tmp -Force
