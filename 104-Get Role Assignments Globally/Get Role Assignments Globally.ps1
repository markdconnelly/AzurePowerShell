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
$role = ""
$arrAAD_Roles = Get-MgDirectoryRole 
$intProgress = 0
foreach($role in $arrAAD_Roles){
    Write-Progress `
    -Activity 'Processing AAD Roles' `
    -Status "$intProgress of $($arrAAD_Roles.Count)" `
    -CurrentOperation $intProgress `
    -PercentComplete (($intProgress /$arrAAD_Roles.Count) * 100)

    $arrRoleMembers = @()
    $member = ""
    $arrRoleMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id
    foreach($member in $arrRoleMembers){
        $psobjRoles += [PSCustomObject]@{
            RoleType = "AAD"
            Scope = "AAD"
            ResourceId = "N/A"
            ResourceName = "N/A"
            ResourceType = "N/A"
            RoleName = $role.DisplayName
            MemberName = $member.AdditionalProperties.displayName
            MemberType = $member.AdditionalProperties.'@odata.type'
            MemberUpn = $member.AdditionalProperties.userPrincipalName
            MemberObjId = $member.Id
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

    $arrRoleAssignments = @()
    $arrRoleAssignments = Get-AzRoleAssignment -Scope $group.GroupId | Where-Object {$_.Scope -eq $group.GroupId}
    foreach($role in $arrRoleAssignments){
        $psobjRoles += [PSCustomObject]@{
            RoleType = "Azure"
            Scope = "Management Group"
            ResourceId = $group.Id
            ResourceName = $group.DisplayName
            ResourceType = "Management Group"
            RoleName = $role.RoleDefinitionName
            MemberName = $role.DisplayName
            MemberType = $role.ObjectType
            MemberUpn = $role.SignInName
            MemberObjId = $role.ObjectId
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

    Set-AzContext -SubscriptionId $sub.Id
    $arrRoleAssignments = @()
    $arrRoleAssignments = Get-AzRoleAssignment | Where-Object {$_.Scope -eq "/subscriptions/$($sub.Id)"}
    foreach($role in $arrRoleAssignments){
        $psobjRoles += [PSCustomObject]@{
            RoleType = "Azure"
            Scope = "Subscription"
            ResourceId = $sub.Id
            ResourceType = "Subscription"
            ResourceName = $sub.Name
            RoleName = $role.RoleDefinitionName
            MemberName = $role.DisplayName
            MemberType = $role.ObjectType
            MemberUpn = $role.SignInName
            MemberObjId = $role.ObjectId
        }
    }
    $intProgress++
}

$arrAzureResourceGroups = @()
$intProgress = 0
foreach($sub in $arrAzureSubscriptions){
    Set-AzContext -SubscriptionId $sub.Id
    $arrAzureResourceGroups += Get-AzResourceGroup
}
foreach($rg in $arrAzureResourceGroups){
    Write-Progress `
    -Activity 'Processing Azure Resource Groups' `
    -Status "$intProgress of $($arrAzureResourceGroups.Count)" `
    -CurrentOperation $intProgress `
    -PercentComplete (($intProgress /$arrAzureResourceGroups.Count) * 100)

    $arrRoleAssignments = @()
    $arrRoleAssignments = Get-AzRoleAssignment -ResourceGroupName $rg.ResourceGroupName | Where-Object {$_.Scope -like "*resourceGroups/$($rg.ResourceGroupName)"}
    foreach($role in $arrRoleAssignments){
        $psobjRoles += [PSCustomObject]@{
            RoleType = "Azure"
            Scope = "Resource Group"
            ResourceId = $rg.ResourceId
            ResourceName = $rg.ResourceGroupName
            ResourceType = "Resource Group"
            RoleName = $role.RoleDefinitionName
            MemberName = $role.DisplayName
            MemberType = $role.ObjectType
            MemberUpn = $role.SignInName
            MemberObjId = $role.ObjectId
        }
    }
    $intProgress++
}

$arrAzureResources = @()
$intProgress = 0
foreach($sub in $arrAzureSubscriptions){
    Set-AzContext -SubscriptionId $sub.Id
    $arrAzureResources += Get-AzResource
}
foreach($resource in $arrAzureResources){
    Write-Progress `
    -Activity 'Processing Azure Resources' `
    -Status "$intProgress of $($arrAzureResources.Count)" `
    -CurrentOperation $intProgress `
    -PercentComplete (($intProgress /$arrAzureResources.Count) * 100)

    $arrRoleAssignments = @()
    $arrRoleAssignments = Get-AzRoleAssignment -Scope $resource.ResourceId | Where-Object {$_.Scope -like "*$($resource.ResourceId)"}
    foreach($role in $arrRoleAssignments){
        $psobjRoles += [PSCustomObject]@{
            RoleType = "Azure"
            Scope = "Resource"
            ResourceId = $resource.ResourceId
            ResourceName = $resource.ResourceName
            ResourceType = $resource.ResourceType
            RoleName = $role.RoleDefinitionName
            MemberName = $role.DisplayName
            MemberType = $role.ObjectType
            MemberUpn = $role.SignInName
            MemberObjId = $role.ObjectId
        }
    }
    $intProgress++
}

# Export to CSV
$dateNow = $null
$strFilePathDate = $null
$strOperationResultsOutput = $null
$dateNow = Get-Date 
$strFilePathDate = $dateNow.ToString("yyyyMMddhhmm")
$strOperationResultsOutput = $strExportDirPath + "Azure_Permissions_Assigned" + $strFilePathDate + ".csv"
$psobjRoles | ConvertTo-Csv | Out-File $strOperationResultsOutput
Write-Host "Export complete. " -ForegroundColor Green
Write-Host "See " + $strOperationResultsOutput + " for a detailed output."$ -ForegroundColor Red -BackgroundColor Yellow