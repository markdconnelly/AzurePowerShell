#   This script assumes that you are connected to Graph via an Application Registration with "UserAuthenticationMethod.ReadWrite.All"

###################### Variables Requiring Input #################
$strImportFilePath = "(Your CSV File & Path Here)"
$strExportFilePath = "(File Path to Store CSVs After Completion)"
###################### Variables Requiring Input #################


######################Variables#################
$arrImportedUsers = @()
$psobjResolvedUsers = @()
$psobjUnresolvedUsers = @()
$arrGetMgUser = @()
$arrEmailParams = @()
$arrPhoneParams = @()
$strUser = ""
$strResolvedUser = ""
$strEmailAddress = ""
$strPhoneNumber = ""
$intProgressStatus = 1
$objError = ""
$dateNow = Get-Date 
$strFilePathDate = $dateNow.ToString("yyyyMMddhhmm")
$strResolvedUserFilePath = $strExportFilePath + "Resolved_Users_" + $strFilePathDate + ".csv"
$strUnresolvedUserFilePath = $strExportFilePath + "Unresolved_Users_" + $strFilePathDate + ".csv"
######################Variables#################

#   This import is critical to the workflow of this script. See the example csv in this folder for details.
#       - CSV "upn" maps to Script $strUser
#       - CSV "email" maps to Script $strEmailAddress
#       - CSV "phone" maps to Script $strPhoneNumber
$arrImportedUsers = Import-Csv -LiteralPath $strImportFilePath

#   Perform data validation
foreach($strUser in $arrImportedUsers){
    $objError = ""
    #   Progress Bar
    Write-Progress `
        -Activity "Checking Users Against Azure" `
        -Status "$intProgressStatus of $($arrImportedUsers.Count)" `
        -CurrentOperation $intProgressStatus `
        -PercentComplete  (($intProgressStatus / @($arrImportedUsers).Count) * 100)
    #   Try/Catch - Resolve Users
    try{
        $arrGetMgUser = Get-MgUser -UserId $strUser
        $psobjResolvedUsers += [PSCustomObject]@{
            Id = $arrGetMgUser.Id
            DisplayName = $arrGetMgUser.DisplayName
            NewEmail = $arrGetMgUser.Mail
            ProvidedEmail = $strUser.mail
            UPN = $arrGetMgUser.UserPrincipalName
            ProvidedPhone = $strUser.phone
        }       
    }catch{
        $objError = Get-Error
        $psobjUnresolvedUsers += [PSCustomObject]@{
            ProvidedUsername = $strUser
            ProvidedEmail = $strUser.mail
            ProvidedPhone = $strUser.phone
            FailureReason = "Unable to resolve"
            RawError = $objError | Out-String
            Id = "N/A"
            DisplayName = "N/A"
            NewEmail = "N/A"
            UPN = "N/A"
        } 
    }
    $intProgressStatus ++
}

#   Set attributes for validated objects
foreach($strResolvedUser in $arrResolvedUsers){
    $intProgressStatus = 1
    $objError = ""
    Write-Progress `
    -Activity "Setting Authentication Information" `
    -Status "$intProgressStatus of $($arrResolvedUsers.Count)" `
    -CurrentOperation $intProgressStatus `
    -PercentComplete  (($intProgressStatus / @($arrResolvedUsers).Count) * 100)

    #   Try/Catch - Test Azure AD User Object
    try{
        $arrEmailParams = @{
            EmailAddress = $strEmailAddress
        }
        $arrPhoneParams = @{
            PhoneNumber = $strPhoneNumber
            PhoneType = "mobile"
        }
        New-MgUserAuthenticationEmailMethod -UserId $strResolvedUser -BodyParameter $arrEmailParams
        New-MgUserAuthenticationPhoneMethod -UserId $strResolvedUser -BodyParameter $arrPhoneParams
    }catch{
        $objError = Get-Error
        $psobjUnresolvedUsers += [PSCustomObject]@{
            ProvidedUsername = $strResolvedUser
            ProvidedEmail = $strResolvedUser.ProvidedEmail
            ProvidedPhone = $strResolvedUser.ProvidedPhone
            FailureReason = "User resolved to Azure AD, but security info was not able to be set"
            RawError = $objError | Out-String
            Id = $strResolvedUser.Id
            DisplayName = $strResolvedUser.DisplayName
            NewEmail = $strResolvedUser.NewEmail
            UPN = $strResolvedUser.UPN
        } 
    }
}
#   export to file
$psobjUnresolvedUsers | ConvertTo-Csv | Out-File $strUnresolvedUserFilePath
$psobjResolvedUsers | ConvertTo-Csv | Out-File $strResolvedUserFilePath
