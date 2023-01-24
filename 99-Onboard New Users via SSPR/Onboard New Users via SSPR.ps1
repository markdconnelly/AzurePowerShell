#   This script assumes that you are connected to Graph via an Application Registration with "UserAuthenticationMethod.ReadWrite.All"

###################### Variables Requiring Input #################
$strImportFilePath = "(Your CSV File & Path Here)"
$strExportDirPath = "(File Directory Path to Store CSVs After Completion)"
###################### Variables Requiring Input #################

#   This import is critical to the workflow of this script. See the example csv in this folder for details.
#       - CSV "upn" maps to Script $strUser
#       - CSV "email" maps to Script $strEmailAddress
#       - CSV "phone" maps to Script $strPhoneNumber
$arrImportedUsers = @()
$arrImportedUsers = Import-Csv -LiteralPath $strImportFilePath

#   Perform data validation
$arrUser = @()
$intProgressStatus = 1
foreach($arrUser in $arrImportedUsers){
    $objError = ""
    $arrGetMgUser = @()
    #   Progress Bar
    Write-Progress `
        -Activity "Checking Users Against Azure" `
        -Status "$($intProgressStatus) of $($arrImportedUsers.Count)" `
        -CurrentOperation $intProgressStatus `
        -PercentComplete  (($intProgressStatus / @($arrImportedUsers).Count) * 100)
    #   Try/Catch - Resolve Users
    $psobjResolvedUsers = @()
    $psobjUnresolvedUsers = @()
    try{
        $arrGetMgUser = Get-MgUser -UserId $arrUser.upn -ErrorAction Stop
        $psobjResolvedUsers += [PSCustomObject]@{
            Id = $arrGetMgUser.Id
            DisplayName = $arrGetMgUser.DisplayName
            NewEmail = $arrGetMgUser.Mail
            ProvidedEmail = $arrUser.email
            UPN = $arrGetMgUser.UserPrincipalName
            ProvidedPhone = $arrUser.phone
        }       
    }catch{
        $objError = $error[0].ToString() #Get-Error
        $psobjUnresolvedUsers += [PSCustomObject]@{
            ProvidedUsername = $arrUser.upn
            ProvidedEmail = $arrUser.mail
            ProvidedPhone = $arrUser.phone
            FailureReason = "Unable to resolve"
            RawError = $objError
            Id = "N/A"
            DisplayName = "N/A"
            NewEmail = "N/A"
            UPN = "N/A"
        } 
    }
    $intProgressStatus ++
}

#   Set attributes for validated objects
$intProgressStatus = 1
$arrResolvedUser = ""
foreach($arrResolvedUser in $psobjResolvedUsers){
    $objError = ""
    $arrEmailParams = $null
    $arrPhoneParams = $null
    Write-Progress `
    -Activity "Setting Authentication Information" `
    -Status "$($intProgressStatus) of $($psobjResolvedUsers.Count)" `
    -CurrentOperation $intProgressStatus `
    -PercentComplete  (($intProgressStatus / @($psobjResolvedUsers).Count) * 100)

    #   Try/Catch - Test Azure AD User Object
    $arrEmailParams = @()
    $arrEmailParams = @{
        EmailAddress = $arrResolvedUser.ProvidedEmail
    }
    $arrPhoneParams = @()
    $arrPhoneParams = @{
        PhoneNumber = "+1 " + $arrResolvedUser.ProvidedPhone
        PhoneType = "mobile"
    }
    try{
        New-MgUserAuthenticationEmailMethod -UserId $arrResolvedUser.UPN -BodyParameter $arrEmailParams -ErrorAction Stop
        New-MgUserAuthenticationPhoneMethod -UserId $arrResolvedUser.UPN -BodyParameter $arrPhoneParams -ErrorAction Stop
    }catch{
        $objError = $error[0].ToString() #Get-Error
        $psobjUnresolvedUsers += [PSCustomObject]@{
            ProvidedUsername = $arrResolvedUser.UPN
            ProvidedEmail = $arrResolvedUser.ProvidedEmail
            ProvidedPhone = $arrResolvedUser.ProvidedPhone
            FailureReason = "User resolved to Azure AD, but security info was not able to be set"
            RawError = $objError
            Id = $arrResolvedUser.Id
            DisplayName = $arrResolvedUser.DisplayName
            NewEmail = $arrResolvedUser.NewEmail
            UPN = $arrResolvedUser.UPN
        } 
    }
    $intProgressStatus ++
}
#   export to file
$dateNow = Get-Date 
$strFilePathDate = $dateNow.ToString("yyyyMMddhhmm")
$strResolvedUserFilePath = $strExportDirPath + "Resolved_Users_" + $strFilePathDate + ".csv"
$strUnresolvedUserFilePath = $strExportDirPath + "Unresolved_Users_" + $strFilePathDate + ".csv"
$psobjUnresolvedUsers | ConvertTo-Csv | Out-File $strUnresolvedUserFilePath
$psobjResolvedUsers | ConvertTo-Csv | Out-File $strResolvedUserFilePath
