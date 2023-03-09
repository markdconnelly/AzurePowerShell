###################### Variables Requiring Input #################
$strExportDirPath = ""
$strExportDirPath = "(Your export directory path here)"
###################### Variables Requiring Input #################

###################### Pre-defined Variables #####################
$strTenantID = ""
$strClientSecret = ""
$strClientID = ""
$strTenantID = Get-Secret -Name PSAppTenantID -AsPlainText
$strClientSecret = Get-Secret -Name PSAppSecret -AsPlainText
$strClientID = Get-Secret -Name PSAppID -AsPlainText
###################### Pre-defined Variables #####################

# This file assumes that you 
#   - Have the Azure PowerShell module installed
#   - Have the Microsoft Graph module installed
#   - Have the ImportExcel module installed
#   - Are authenticating using a Service Principal with the following permissions:
#       - Azure Resource > Global Reader Permissions
#       - Microsoft Graph > User.Read.All

# Connect to MS Graph
$strAPI_URI = ""
$arrAPI_Body = @{}
$objAccessTokenRaw = ""
$objAccessToken = ""
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
$arrAAD_Roles = @()
$psobjRoles = @()
$arrAAD_Roles = Get-MgDirectoryRole 
$intProgress = 0
foreach($role in $arrAAD_Roles){
    Write-Progress `
    -Activity 'Processing AAD Roles' `
    -Status "$intProgress of $($arrAAD_Roles.Count)" `
    -CurrentOperation $intProgress `
    -PercentComplete (($intProgress /$arrAAD_Roles.Count) * 100)
    -Id 1

    $arrRoleMembers = @()
    $arrRoleMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id
    foreach($member in $arrRoleMembers){
        $psobjRoles += [PSCustomObject]@{
            RoleType = "AAD"
            Scope = "AAD"
            ResourceId = "N/A"
            ResourceName = "N/A"
            ResourceType = "N/A"
            RoleName = $role.DisplayName
            MemberName = $member.DisplayName
            MemberUpn = $member.UserPrincipalName
            MemberType = $member.ObjectType
            MemberObjId = $member.ObjectId
        }
    }
    $intProgress++
} 


# Connect to Azure Resources
$strClientSecretSecured = ""
$strClientSecretSecured = ConvertTo-SecureString $strClientSecret -AsPlainText -Force
$objServicePrincipalCredential = ""
$objServicePrincipalCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $strClientID, $strClientSecretSecured
Connect-AzAccount -ServicePrincipal -Credential $objServicePrincipalCredential -Tenant $strTenantID
$arrAzureManagementGroups = @()
$intProgress = 0
$arrAzureManagementGroups = Get-AzManagementGroup
foreach($group in $arrAzureManagementGroups){
    Write-Progress `
    -Activity 'Processing Azure Management Groups' `
    -Status "$intProgress of $($arrAzureManagementGroups.Count)" `
    -CurrentOperation $intProgress `
    -PercentComplete (($intProgress /$arrAzureManagementGroups.Count) * 100)
    -Id 2

    $arrRoleAssignments = @()
    $arrRoleAssignments = Get-AzRoleAssignment -ObjectId $group.GroupId
    foreach($role in $arrRoleAssignments){
        $psobjRoles += [PSCustomObject]@{
            RoleType = "Azure"
            Scope = "Management Group"
            ResourceId = $group.GroupId
            ResourceName = $group.DisplayName
            ResourceType = "Management Group"
            RoleName = $role.RoleDefinitionName
            MemberName = $role.DisplayName
            MemberUpn = $role.UserPrincipalName
            MemberType = $role.PrincipalType
            MemberObjId = $role.PrincipalId
        }
    }
    $intProgress++
}

$arrAzureSubscriptions = @()
$intProgress = 0
$arrAzureSubscriptions = Get-AzSubscription
foreach($sub in $arrAzureSubscriptions){
    Write-Progress `
    -Activity 'Processing Azure Subscriptions' `
    -Status "$intProgress of $($arrAzureSubscriptions.Count)" `
    -CurrentOperation $intProgress `
    -PercentComplete (($intProgress /$arrAzureSubscriptions.Count) * 100)
    -Id 3

    $arrRoleAssignments = @()
    $arrRoleAssignments = Get-AzRoleAssignment -ObjectId $sub.SubscriptionId
    foreach($role in $arrRoleAssignments){
        $psobjRoles += [PSCustomObject]@{
            RoleType = "Azure"
            Scope = "Subscription"
            ResourceId = $sub.SubscriptionId
            ResourceType = "Subscription"
            ResourceName = $sub.DisplayName
            RoleName = $role.RoleDefinitionName
            MemberName = $role.DisplayName
            MemberUpn = $role.UserPrincipalName
            MemberType = $role.PrincipalType
            MemberObjId = $role.PrincipalId
        }
    }
    $intProgress++
}

$arrAzureResourceGroups = @()
$intProgress = 0
$arrAzureResourceGroups = Get-AzResourceGroup
foreach($rg in $arrAzureResourceGroups){
    Write-Progress `
    -Activity 'Processing Azure Resource Groups' `
    -Status "$intProgress of $($arrAzureResourceGroups.Count)" `
    -CurrentOperation $intProgress `
    -PercentComplete (($intProgress /$arrAzureResourceGroups.Count) * 100)
    -Id 4

    $arrRoleAssignments = @()
    $arrRoleAssignments = Get-AzRoleAssignment -ObjectId $rg.ResourceId
    foreach($role in $arrRoleAssignments){
        $psobjRoles += [PSCustomObject]@{
            RoleType = "Azure"
            Scope = "Resource Group"
            ResourceId = $rg.ResourceId
            ResourceName = $rg.ResourceGroupName
            ResourceType = "Resource Group"
            RoleName = $role.RoleDefinitionName
            MemberName = $role.DisplayName
            MemberUpn = $role.UserPrincipalName
            MemberType = $role.PrincipalType
            MemberObjId = $role.PrincipalId
        }
    }
    $intProgress++
}

$arrAzureResources = @()
$intProgress = 0
$arrAzureResources = Get-AzResource
foreach($resource in $arrAzureResources){
    Write-Progress `
    -Activity 'Processing Azure Resources' `
    -Status "$intProgress of $($arrAzureResources.Count)" `
    -CurrentOperation $intProgress `
    -PercentComplete (($intProgress /$arrAzureResources.Count) * 100)
    -Id 5

    $arrRoleAssignments = @()
    $arrRoleAssignments = Get-AzRoleAssignment -ObjectId $resource.ResourceId
    foreach($role in $arrRoleAssignments){
        $psobjRoles += [PSCustomObject]@{
            RoleType = "Azure"
            Scope = "Resource"
            ResourceId = $resource.ResourceId
            ResourceName = $resource.ResourceName
            ResourceType = $resource.ResourceType
            RoleName = $role.RoleDefinitionName
            MemberName = $role.DisplayName
            MemberUpn = $role.UserPrincipalName
            MemberType = $role.PrincipalType
            MemberObjId = $role.PrincipalId
        }
    }
    $intProgress++
}

# Export to CSV
#   export to file
$dateNow = $null
$strFilePathDate = $null
$strOperationResultsOutput = $null
$dateNow = Get-Date 
$strFilePathDate = $dateNow.ToString("yyyyMMddhhmm")
$strOperationResultsOutput = $strExportDirPath + "Azure_Permissions_Assigned" + $strFilePathDate + ".csv"
$psobjRoles | ConvertTo-Csv | Out-File $strOperationResultsOutput
Write-Host "Export complete. " -ForegroundColor Green
Write-Host "See " + $strOperationResultsOutput + " for a detailed output."$ -ForegroundColor Red -BackgroundColor Yellow