param (
    [string]$appName = "CVExchangeOnlineApp"
)

Import-Module AzureAD

$aesManaged = New-Object "System.Security.Cryptography.AesManaged"
$aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
$aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::Zeros
$aesManaged.BlockSize = 128
$aesManaged.KeySize = 256
$aesManaged.GenerateKey()
$apppwd = ([System.Convert]::ToBase64String($aesManaged.Key))

$credential = Get-Credential -Message "O365 Admin Account" xxx@xxx.onmicrosoft.com
$Conn = Connect-AzureAD -Credential $credential
$Guid = New-Guid
$startDate = Get-Date

$PasswordCredential = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordCredential
$PasswordCredential.StartDate = $startDate
$PasswordCredential.EndDate = $startDate.AddYears(10)
$PasswordCredential.KeyId = $Guid.ToString()
$PasswordCredential.Value = $apppwd

$appURI = "https://$($appName).$($conn.TenantDomain)"
$appHomePageUrl = "http://localhost:1234"
$appReplyURLs = @("http://localhost:1234")
if(!($myApp = Get-AzureADApplication -Filter "DisplayName eq '$($appName)'"  -ErrorAction SilentlyContinue))
{
    $svcprincipal = Get-AzureADServicePrincipal -All $true | ? { $_.DisplayName -match "Microsoft Graph" }
    $reqGraph = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
    $reqGraph.ResourceAppId = $svcprincipal.AppId

    $permission = $svcprincipal.AppRoles | ? { $_.DisplayName -match "Read directory data" }
    $permission3 = $svcprincipal.Oauth2Permissions | ? { $_.AdminConsentDisplayName -match "Read directory data" }

    $appPermission1 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $permission.Id,"Role"
    $delPermission3 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $permission3.Id,"Scope"

    $svcprincipal2 = Get-AzureADServicePrincipal -All $true | ? { $_.DisplayName -match "Windows Azure Active Directory" }
    $permission2 = $svcprincipal2.Oauth2Permissions | ? { $_.AdminConsentDisplayName -match "Sign in and read user profile" }
    $delPermission2 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $permission2.Id,"Scope"

    $reqAD = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
    $reqAD.ResourceAppId = $svcprincipal2.AppId


    $reqGraph.ResourceAccess = $delPermission3, $appPermission1
    $reqAD.ResourceAccess = $delPermission2
    $myApp = New-AzureADApplication -DisplayName $appName -IdentifierUris $appURI -Homepage $appHomePageUrl -ReplyUrls $appReplyURLs -PasswordCredentials $PasswordCredential -AvailableToOtherTenants $true -RequiredResourceAccess @($reqGraph, $reqAD)
    $myAppsp = New-AzureADServicePrincipal -AccountEnabled $true -AppId $myApp.AppId -AppRoleAssignmentRequired $true -DisplayName $myApp.DisplayName -Tags {WindowsAzureActiveDirectoryIntegratedApp}

    Write-Host "Application Name: " $myApp.DisplayName
    Write-Host "Tenant ID: "  $conn.TenantId
    Write-Host "Application ID: " $myApp.AppId
    Write-Host "Application Password: " $apppwd
    Write-Host ""
    Write-Host "Please Grant Permissions for $($myApp.DisplayName) on Azure Portal. Go to Settings -> Required Permissions and click on the Grant Permissions option."
    Write-Host "URL: " "https://portal.azure.com/#blade/Microsoft_AAD_IAM/ApplicationBlade/appId/$($myApp.AppId)/objectId/$($myApp.ObjectId)"

} Else {
Write-Host "App $($myApp.DisplayName) already exists."
}
