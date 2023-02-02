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
    $objError = @()
    $arrGetMgUser = @()
    Write-Progress `
    -Activity "Building User Database" `
    -Status "$($intProgressStatus) of $($arrAllUsers.Count)" `
    -CurrentOperation $intProgressStatus `
    -PercentComplete  (($intProgressStatus / @($arrAllUsers).Count) * 100)
    #   Try/Catch - Resolve Users
    try{
        #variables
        $arrGetMgUser = Get-MgUser -UserId $arrUser.Id -ErrorAction Stop
        $arrPhones = @()
        $arrAuthMethods = @()
        $arrAppRoleAssignments = @()
        $arrOnPremiseData = @()
        $arrUserManager = @()
        $strUserManagerProcessed = ""
        $arrUserManages = @()
        $strPriority = ""
        $arrLicenses = @()
        $arrMemberOf = @()
        $arrOauthPermissionGrants = @()
        $arrManagedAppRegistrations = @()
        $arrUserOwnedDevices = @()
        $arrUserRegisteredDevices = @()
        $arrUserDevices = @()
        try{
            $arrUserManager = Get-MgUserManager -UserId $arrGetMgUser.Id -ErrorAction Stop
            $strUserManagerProcessed = $arrUserManager.AdditionalProperties.DisplayName 
        }catch{
            $strManagerError = $Error[0].Exception.Message
            $objError += $strManagerError
            $strUserManagerProcessed = "No Manager"
        }
        try {
            $arrUserManages = Get-MgUserDirectReport -UserId $arrGetMgUser.Id -ErrorAction Stop
            $arrUserManages = $arrUserManages.AdditionalProperties.DisplayName 
        }
        catch {
            $objError += Get-Error
            $arrUserManages = "No Direct Reports"
        }
        try {
            $arrLicenses = Get-MgUserLicenseDetail -UserId $arrGetMgUser.Id -ErrorAction Stop
        }
        catch {
            $objError += Get-Error
            $arrLicenses = "No Licenses"
        }
        try {
            $arrMemberOf = Get-MgUserMemberOf -UserId $arrGetMgUser.Id -ErrorAction Stop
        }
        catch {
            $objError += Get-Error
            $arrMemberOf = "No MemberOf"
        }
        #parse oauthPermissionGrants object
        try {
            $arrOauthPermissionGrants = Get-MgUserOauth2PermissionGrant -UserId $arrGetMgUser.Id -ErrorAction Stop
        }
        catch {
            $objError += Get-Error
            $arrOauthPermissionGrants = "No OAuth Permission Grants"
        }
        #parse managedAppRegistrations object
        try {
            $arrManagedAppRegistrations = Get-MgUserManagedAppRegistration -UserId $arrGetMgUser.Id -ErrorAction Stop
        }
        catch {
            $objError += Get-Error
            $arrManagedAppRegistrations = "No Managed App Registrations"
        }
        #parse devices object
        try {
            $arrUserOwnedDevices = Get-MgUserOwnedDevice -UserId $arrGetMgUser.Id -ErrorAction SilentlyContinue
            
        }catch {
            $objError += Get-Error
            $arrUserOwnedDevices = "No Owned Devices"
        }
        try {
            $arrUserRegisteredDevices = Get-MgUserRegisteredDevice -UserId $arrGetMgUser.Id -ErrorAction SilentlyContinue
        }catch {
            $objError += Get-Error
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
        $objError += Get-Error
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
        Enabled = ""
        Error = $objError
    }  
    $intProgressStatus++
}


#   export to file
$dateNow = Get-Date 
$strFilePathDate = $dateNow.ToString("yyyyMMddhhmm")
$strResolvedUserFilePath = $strExportDirPath + "UserDatabase_" + $strFilePathDate + ".csv"
$psobjUsersDatabase | ConvertTo-Csv | Out-File $strResolvedUserFilePath

https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.users/update-mguser?view=graph-powershell-1.0
-AccountEnabled
-Authentication
-AuthorizationIfo
-Calendars
-Drive
-Drives
-EmployeeType
-JoinedTeams
-LastPasswordChangeDateTime
