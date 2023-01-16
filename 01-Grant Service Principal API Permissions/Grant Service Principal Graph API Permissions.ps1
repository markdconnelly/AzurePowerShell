$strTenantID = Get-Secret -Name PSAppTenantID -AsPlainText
$strAppDisplayName = Get-Secret -Name PSAppDisplayName -AsPlainText
$strMSIDisplayName = Get-Secret -Name PSMSIDisplayName -AsPlainText
$GraphAppId = "00000003-0000-0000-c000-000000000000"
#create an array of all the permissions you want to grant
$PermissionNames = @()
$PermissionNames = @(
    "Application.Read.All"
    "AuditLog.Read.All"
    "BitlockerKey.Read.All"
    "Contacts.Read"
    "Device.Read.All"
    "Directory.Read.All"
    "Domain.Read.All"
    "Group.Read.All"
    "DeviceManagementApps.Read.All"
    "DeviceManagementConfiguration.Read.All"
    "DeviceManagementManagedDevices.Read.All"
    "DeviceManagementRBAC.Read.All"
    "PrivilegedAccess.Read.AzureAD"
    "PrivilegedAccess.Read.AzureADGroup"
    "PrivilegedAccess.Read.AzureResources"
    "Policy.Read.All"
    "RoleManagement.Read.All"
    "User.Read.All"
)

#This connection is done as a user. You will have to grant these permissions for your user Context to the Graph API application. 
Connect-MgGraph -TenantId $strTenantID -Scopes ("Application.Read.All","AppRoleAssignment.ReadWrite.All","Directory.Read.All")
$MSI = (Get-MgServicePrincipal -Filter "displayName eq '$strMSIDisplayName'")
$App = (Get-MgServicePrincipal -Filter "displayname eq '$strAppDisplayName'")
Start-Sleep -Seconds 10
$GraphServicePrincipal = Get-MgServicePrincipal -Filter "appId eq '$GraphAppId'"

foreach($permission in $PermissionNames){
    $AppRole = $GraphServicePrincipal.AppRoles | Where-Object {$_.Value -eq $permission -and $_.AllowedMemberTypes -contains "Application"}
    $loopMSIParams = @{
        PrincipalId = $MSI.Id
        ResourceId = $GraphServicePrincipal.Id
        AppRoleId = $AppRole.Id
    }
    $loopAppParams = @{
        PrincipalId = $App.Id
        ResourceId = $GraphServicePrincipal.Id
        AppRoleId = $AppRole.Id
    }
        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $MSI.Id -BodyParameter $loopMSIParams

        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $App.Id -BodyParameter $loopAppParams   
}