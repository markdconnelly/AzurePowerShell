$strClientID = Get-Secret -Name PSAppID -AsPlainText
$strTenantID = Get-Secret -Name PSAppTenantID -AsPlainText
$strClientSecret = Get-Secret -Name PSAppSecret -AsPlainText
$strAPI_URI = "https://login.microsoftonline.com/$strTenantID/oauth2/token"
$arrAPI_Body = @{
    grant_type = "client_credentials"
    client_id = $strClientID
    client_secret = $strClientSecret
    resource = "https://graph.microsoft.com"
}
$objAccessTokenRaw = Invoke-RestMethod -Method Post -Uri $strAPI_URI -Body $arrAPI_Body -ContentType "application/x-www-form-urlencoded"
$objAccessToken = $objAccessTokenRaw.access_token
Connect-Graph -Accesstoken $objAccessToken
#   Define the azure ad roles that will trigger this automation. Add any privileged roles that are not included in the default list
#   region $psobjPrivilegedRoles
$arrPrivilegedRoleIds = @()
$arrPrivilegedRoleIds = @(
    "4c792954-03e9-432f-a34a-681ad846728b"
    "af287b25-973e-4533-8f7b-78da3c934b38"
    "ea76ff1c-fbca-41ae-b7ec-1a96bf3b5e13"
    "8aa127f4-ced9-4b9d-b731-49f139962957"
    "442e5ca5-5e64-4124-b50c-dd63def34c83"
    "58573c7b-4177-41ef-98bf-37ff8e51fd99"
    "94e51f36-4cb7-4669-a66f-250c38cf19e6"
    "bbca776b-7420-4d70-94d7-fe6c1d3e8c45"
    "b1e6af4a-060b-4e12-ad7f-5197e3799631"
    "5b39d8d3-6433-4394-86a8-4acbcc73d934"
    "e674d99d-5abd-4c7e-89da-d88f067458f6"
    "b02fb3d8-bac0-4257-9c9d-386cb4b988ec"
    "187b0f19-3bd8-490e-845e-8c914b30f57e"
    "067cacdc-2929-42d8-896d-442a02dde73a"
    "ebb653d4-427b-4950-968a-6cec02501359"
    "f120e982-0450-4d6d-b1fd-8d30e5c0da9c"
    "8e392b51-268e-4288-9bb7-e1380018a6a3"
    "a2bca6eb-de5c-411e-b91e-c67904a82806"
    "b3154b24-f5e6-476e-87ee-67f9939799f0"
    "2d1ec1ef-c018-4009-a928-fc7061d8697c"
    "97bab316-8cec-4b9f-91e9-b7ce48e5d6f6"
    "cf1fdae3-a142-4214-bcfa-6e9c724df884"
    "b62300c4-588f-48b8-a5a3-8ad7f4a40d90"
    "59607476-aab9-4884-8534-c97945a3df68"
    "18ef515a-7c0e-4711-b723-edfda0eb171f"
    "8499b983-7e65-4a86-85b4-c79bc387f630"
    "02c5beff-0b31-4aa8-a256-458bf7d84d01"
    "6501a9a8-997a-44a1-bf79-ff47fcb3e560"    
)
$psobjPrivilegedRoles = @()
$intSuccessCount = 0
$intFailureCount = 0
foreach($id in $arrPrivilegedRoleIds){
    $objError = $null
    try {
        $arrRoleDetails = @()
        $arrRoleDetails = Get-MgDirectoryRole -DirectoryRoleId $id -ErrorAction Stop
        $psobjPrivilegedRoles += [PSCustomObject]@{
            RoleId = $arrRoleDetails.Id
            RoleName = $arrRoleDetails.DisplayName
            Description = $arrRoleDetails.Description
        }
        $intSuccessCount ++
    }
    catch {
        $objError = $Error[0].Exception.Message
        Write-Host "Error: Could not find Role ID: $id - $objError"
        $intFailureCount ++
    }
}
#   endregion $psobjPrivilegedRoles
Write-Host "Success: $intSuccessCount"
Write-Host "Failure: $intFailureCount"
#  Get members with privileged roles in azure ad / 
$intSuccessCount = 0
$intFailureCount = 0
$psobjPrivilegedUsers = @()
foreach($role in $psobjPrivilegedRoles){
    try{
        $arrDirectoryRoleMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $role.RoleId -ErrorAction Stop
        foreach($member in $arrDirectoryRoleMembers){
            $psobjPrivilegedUsers += [PSCustomObject]@{
                userPrincipalName = $member.AdditionalProperties.userPrincipalName
                displayName = $member.AdditionalProperties.displayName
                givenName = $member.AdditionalProperties.givenName
                surname = $member.AdditionalProperties.surname
                mail = $member.AdditionalProperties.mail
                role = $role.DisplayName
            } 
            $intSuccessCount ++
        }
    }catch{
        $objError = $Error[0].Exception.Message
        $intFailureCount ++
        Write-Host "Error: Could not find members for Role: $($role.DisplayName) - $objError"
    }
}
Write-Host "Success: $intSuccessCount"
Write-Host "Failure: $intFailureCount"
#connect to azure account and look for privileged users
$objCredentials = $null
$objCredentials = New-Object System.Management.Automation.PSCredential -ArgumentList $strClientID, $strClientSecret
Connect-AzAccount -ServicePrincipal -TenantId $strTenantID -Credential $objCredentials
$arrUniquePrivilegedUsers = $psobjPrivilegedUsers | Sort-Object -Property userPrincipalName -Unique | Select-Object -Property userPrincipalName, displayName, givenName, surname, mail 
#connect to exchange online
$strAppCertThumbprint = ""
$strAppCertThumbprint = Get-Secret -Name PSAppCert -AsPlainText
$strAppOrgName = ""
$strAppOrgName = Get-Secret -Name PSAppOrganizationName -AsPlainText
$strAppID = ""
$strAppID = Get-Secret -Name PSAppID -AsPlainText
#Connect-ExchangeOnline -CertificateThumbPrint $strAppCertThumbprint -AppID  $strAppID -Organization $strAppOrgName 















<#
#   Correlate and deduplicate list to find a complete list of priority users by user principal name
$id = "b3154b24-f5e6-476e-87ee-67f9939799f0"
$testDirectoryRoleMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $test
foreach($member in $testDirectoryRoleMembers){
    $testDirectoryRoleMembersParsed = $member.AdditionalProperties.DisplayName
    $testDirectoryRoleMembersParsed

}
$testDirectoryRoleMembersParsed = $testDirectoryRoleMembers.AdditionalProperties

$testDirectoryRoleMembers | ConvertTo-Json -Depth 10 | Out-File -FilePath "C:\Temp\testrolemember.json"

$testGetDirectoryRole = Get-MgDirectoryRole -DirectoryRoleId $test
$testGetDirectoryRole | ConvertTo-Json -Depth 10 | Out-File -FilePath "C:\Temp\testgetdirectoryrole.json"
$testGetDirectoryRole | ConvertTo-Csv | Out-File -FilePath "C:\Temp\testgetdirectoryrole.csv"

#>