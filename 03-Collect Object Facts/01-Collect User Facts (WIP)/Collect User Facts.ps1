###################### Variables Requiring Input #################
$strExportDirPath = "(File Directory Path to Store CSVs After Completion)"
###################### Variables Requiring Input #################

#region Parser Functions
# It is assumed at this point that you are connected to the Microsoft Graph API with User.Read.All permissions
$arrAllUsers = @()
$arrAllUsers = Get-MgUser -All $true
$arrUser = @()
$intProgressStatus = 1
$psobjUsersDatabase = @()
foreach($arrUser in $arrAllUsers){
    $objError = ""
    $arrGetMgUser = @()
    Write-Progress `
    -Activity "Building User Database" `
    -Status "$($intProgressStatus) of $($arrAllUsers.Count)" `
    -CurrentOperation $intProgressStatus `
    -PercentComplete  (($intProgressStatus / @($arrAllUsers).Count) * 100)
    #   Try/Catch - Resolve Users
    try{
        #region variables
        $arrGetMgUser = Get-MgUser -UserId $arrUser.Id -ErrorAction Stop
        $arrPhones = @()
        $arrAuthMethods = @()
        $arrAppRoleAssignments = @()
        $arrOnPremiseData = @()
        $arrUserManager = @()
        $strUserManager = ""
        $arrUserManages = @()
        $strPriority = ""
        $arrLicenses = @()
        $arrMemberOf = @()
        $arrOauthPermissionGrants = @()
        $arrManagedAppRegistrations = @()
        $arrUserOwnedDevices = @()
        $arrUserRegisteredDevices = @()
        $arrUserDevices = @()#endregion
        
        #region ParseManagerObject
        try{
            $arrUserManager = Get-MgUserManager -UserId $arrGetMgUser.Id -ErrorAction Stop
            $strUserManager = $arrUserManager.AdditionalProperties.DisplayName 
        }catch{
            $strUserManager = "No Manager"
        }#endregion 

        #region parse manages object
        try {
            $arrUserManages = Get-MgUserDirectReport -UserId $arrGetMgUser.Id -ErrorAction Stop
            $arrUserManages = $arrUserManages.AdditionalProperties.DisplayName 
        }
        catch {
            $arrUserManages = "No Direct Reports"
        }#endregion
        
        #parse license object
        try {
            $arrLicenses = Get-MgUserLicenseDetail -UserId $arrGetMgUser.Id -ErrorAction Stop
        }
        catch {
            $arrLicenses = "No Licenses"
        }
        #parse memberOf object
        try {
            $arrMemberOf = Get-MgUserMemberOf -UserId $arrGetMgUser.Id -ErrorAction Stop
        }
        catch {
            $arrMemberOf = "No MemberOf"
        }
        #parse oauthPermissionGrants object
        try {
            $arrOauthPermissionGrants = Get-MgUserOauth2PermissionGrant -UserId $arrGetMgUser.Id -ErrorAction Stop
        }
        catch {
            $arrOauthPermissionGrants = "No OAuth Permission Grants"
        }
        #parse managedAppRegistrations object
        try {
            $arrManagedAppRegistrations = Get-MgUserManagedAppRegistration -UserId $arrGetMgUser.Id -ErrorAction Stop
        }
        catch {
            $arrManagedAppRegistrations = "No Managed App Registrations"
        }
        #parse devices object
        try {
            $arrUserOwnedDevices = Get-MgUserOwnedDevice -UserId $arrGetMgUser.Id -ErrorAction SilentlyContinue
            
        }catch {
            $arrUserOwnedDevices = "No Owned Devices"
        }
        try {
            $arrUserRegisteredDevices = Get-MgUserRegisteredDevice -UserId $arrGetMgUser.Id -ErrorAction SilentlyContinue
        }catch {
            $arrUserRegisteredDevices = "No Registered Devices"
        }
        $arrUserDevices = $arrUserOwnedDevices + $arrUserRegisteredDevices #polish this up later

        #collect authentication methods - TBD
        $arrAuthMethods = $arrGetMgUser.Authentication.AuthenticationMethods.Id
        #collect app role assignments - TBD
        $arrAppRoleAssignments = GEt-mgus
        #collect on-premise data - TBD

        #collect phone numbers - TBD

        #calculate prirority - TBD
        $strPriority = "TBD"
    }
    catch{
        $objError = Get-Error
    }
    $psobjUsersDatabase += [PSCustomObject]@{
        Id = $arrGetMgUser.Id
        EmployeeID = $arrGetMgUser.EmployeeId
        Photo = $arrGetMgUser.Photo
        Priority = $strPriority
        DisplayName = $arrGetMgUser.DisplayName
        FirstName = $arrGetMgUser.GivenName
        LastName = $arrGetMgUser.Surname
        UPN = $arrGetMgUser.UserPrincipalName
        EmailAddress = $arrGetMgUser.Mail
        Phones = $arrPhones
        JobTitle = $arrGetMgUser.JobTitle
        Manager = $strUserManager
        Manages = $arrUserManages
        Licenses = $arrLicenses
        PasswordPolicies = $arrGetMgUser.PasswordPolicies
        AuthenticationMethods = $arrAuthMethods
        AppRoleAssignments = $arrAppRoleAssignments
        MemberOf = $arrMemberOf
        OauthPermissionGrants = $arrOauthPermissionGrants
        Devices = $arrUserDevices
        ManagedAppRegistrations = $arrManagedAppRegistrations
        OwnedObjects = $arrGetMgUser.OwnedObjects
        Birthday = $arrGetMgUser.Birthday
        StreetAddress = $arrGetMgUser.StreetAddress
        State = $arrGetMgUser.State
        City = $arrGetMgUser.City
        ZipCode = $arrGetMgUser.ZipCode
        Country = $arrGetMgUser.Country
        EmployeeHireDate = $arrGetMgUser.HireDate
        ProxyAddresses = $arrGetMgUser.ProxyAddresses
        OnPremiseData = $arrOnPremiseData
        Error = $objError
    }   
    $intProgressStatus++
}


#   export to file
$dateNow = Get-Date 
$strFilePathDate = $dateNow.ToString("yyyyMMddhhmm")
$strResolvedUserFilePath = $strExportDirPath + "UserDatabase_" + $strFilePathDate + ".csv"
$psobjUsersDatabase | ConvertTo-Csv | Out-File $strResolvedUserFilePath
