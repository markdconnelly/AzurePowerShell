
$strTenantID = Get-Secret -Name PSAppTenantID -AsPlainText
$strAppDisplayName = Get-Secret -Name PSAppDisplayName -AsPlainText
$strMSIDisplayName = Get-Secret -Name PSMSIDisplayName -AsPlainText
$GraphAppId = "00000003-0000-0000-c000-000000000000"
#create an array of all the permissions you want to grant
$PermissionNames = @(
    "AccessReview.Read.All"
    "AdministrativeUnit.Read.All"
    "AppCatalog.Read.All"
    "Application.Read.All"
    "AuditLog.Read.All"
    "BitlockerKey.Read.All"
    "Bookings.Read.All"
    "BrowserSiteLists.Read.All"
    "Calendars.Read"
    "CallRecords.Read.All"
    "Channel.ReadBasic.All"
    "ChannelMember.Read.All"
    "ChannelMessage.Read.All"
    "ChannelSettings.Read.All"
    "Chat.Read.All"
    "ChatMember.Read.All"
    "CloudPC.Read.All"
    "ConsentRequest.Read.All"
    "Contacts.Read"
    "Device.Read.All"
    "Directory.Read.All"
    "Domain.Read.All"
    "eDiscovery.Read.All"
    "Files.Read.All"
    "Group.Read.All"
    "IdentityProvider.Read.All"
    "IdentityRiskEvent.Read.All"
    "SecurityIncident.Read.All"
    "InformationProtectionPolicy.Read.All"
    "DeviceManagementApps.Read.All"
    "DeviceManagementConfiguration.Read.All"
    "DeviceManagementManagedDevices.Read.All"
    "DeviceManagementRBAC.Read.All"
    "Mail.Read"
    "ManagedTenants.Read.All"
    "Notes.Read.All"
    "OnlineMeetings.Read.All"
    "Organization.Read.All"
    "OrgContact.Read.All"
    "People.Read.All"
    "PrivilegedAccess.Read.AzureAD"
    "PrivilegedAccess.Read.AzureADGroup"
    "PrivilegedAccess.Read.AzureResources"
    "Place.Read.All"
    "Policy.Read.All"
    "ProgramControl.Read.All"
    "RecordsManagement.Read.All"
    "Reports.Read.All"
    "RoleManagement.Read.All"
    "AttackSimulation.Read.All"
    "SecurityActions.Read.All"
    "SecurityAlert.Read.All"
    "SecurityEvents.Read.All"
    "SecurityIncident.Read.All"
    "ThreatIndicators.Read.All"
    "Sites.Read.All"
    "Team.ReadBasic.All"
    "TeamSettings.Read.All"
    "TeamsActivity.Read.All"
    "Team.ReadBasic.All"
    "TeamsTab.Read.All"
    "User.Read.All"
)

#This connection is done as a user. You will have to grant these permissions for your user Context to the Graph API application. 
Connect-MgGraph -TenantId $strTenantID -Scopes ("Application.Read.All","AppRoleAssignment.ReadWrite.All","Directory.Read.All")
$MSI = (Get-MgServicePrincipal -Filter "displayName eq '$strAppDisplayName'")
$App = (Get-MgServicePrincipal -Filter "displayname eq '$strMSIDisplayName'")
Start-Sleep -Seconds 10
$GraphServicePrincipal = Get-MgServicePrincipal -Filter "appId eq '$GraphAppId'"

foreach($permission in $PermissionNames){
    $AppRole = $GraphServicePrincipal.AppRoles | `
        Where-Object {$_.Value -eq $permission -and $_.AllowedMemberTypes -contains "Application"}
    
        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $MSI.Id -PrincipalId $MSI.Id `
        -ResourceId $GraphServicePrincipal.Id -Id $AppRole.Id

        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $App.Id -PrincipalId $App.Id `
        -ResourceId $GraphServicePrincipal.Id -Id $AppRole.Id       

}