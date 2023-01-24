#   This script assumes that you are connected to Graph via an Application Registration with "UserAuthenticationMethod.ReadWrite.All"

###################### Variables Requiring Input #################
$strImportFilePath = "(Your CSV File & Path Here)"
$strExportDirPath = "(File Directory Path to Store CSVs After Completion)"
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
$strResolvedUserFilePath = $strExportDirPath + "Resolved_Users_" + $strFilePathDate + ".csv"
$strUnresolvedUserFilePath = $strExportDirPath + "Unresolved_Users_" + $strFilePathDate + ".csv"
######################Variables#################

#   This import is critical to the workflow of this script. See the example csv in this folder for details.
#       - CSV "upn" maps to Script $strUser
#       - CSV "email" maps to Script $strEmailAddress
#       - CSV "phone" maps to Script $strPhoneNumber
$arrImportedUsers = Import-Csv -LiteralPath $strImportFilePath

#   Perform data validation
foreach($strUser in $arrImportedUsers){
    $objError = ""
    $arrGetMgUser = ""
    #   Progress Bar
    Write-Progress `
        -Activity "Checking Users Against Azure" `
        -Status "$($intProgressStatus) of $($arrImportedUsers.Count)" `
        -CurrentOperation $intProgressStatus `
        -PercentComplete  (($intProgressStatus / @($arrImportedUsers).Count) * 100)
    #   Try/Catch - Resolve Users
    try{
        $arrGetMgUser = Get-MgUser -UserId $strUser.upn -ErrorAction Stop
        $psobjResolvedUsers += [PSCustomObject]@{
            Id = $arrGetMgUser.Id
            DisplayName = $arrGetMgUser.DisplayName
            NewEmail = $arrGetMgUser.Mail
            ProvidedEmail = $strUser.mail
            UPN = $arrGetMgUser.UserPrincipalName
            ProvidedPhone = $strUser.phone
        }       
    }catch{
        $objError = $error[0].ToString() #Get-Error
        $psobjUnresolvedUsers += [PSCustomObject]@{
            ProvidedUsername = $strUser.upn
            ProvidedEmail = $strUser.mail
            ProvidedPhone = $strUser.phone
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
foreach($strResolvedUser in $psobjResolvedUsers){
    $objError = ""
    Write-Progress `
    -Activity "Setting Authentication Information" `
    -Status "$($intProgressStatus) of $($psobjResolvedUsers.Count)" `
    -CurrentOperation $intProgressStatus `
    -PercentComplete  (($intProgressStatus / @($psobjResolvedUsers).Count) * 100)

    #   Try/Catch - Test Azure AD User Object
    $arrEmailParams = @{
        EmailAddress = $strEmailAddress
    }
    $arrPhoneParams = @{
        PhoneNumber = $strPhoneNumber
        PhoneType = "mobile"
    }
    try{
        New-MgUserAuthenticationEmailMethod -UserId $strResolvedUser.UPN -BodyParameter $arrEmailParams -ErrorAction Stop
        New-MgUserAuthenticationPhoneMethod -UserId $strResolvedUser.UPN -BodyParameter $arrPhoneParams -ErrorAction Stop
    }catch{
        $objError = $error[0].ToString() #Get-Error
        $psobjUnresolvedUsers += [PSCustomObject]@{
            ProvidedUsername = $strResolvedUser.UPN
            ProvidedEmail = $strResolvedUser.ProvidedEmail
            ProvidedPhone = $strResolvedUser.ProvidedPhone
            FailureReason = "User resolved to Azure AD, but security info was not able to be set"
            RawError = $objError
            Id = $strResolvedUser.Id
            DisplayName = $strResolvedUser.DisplayName
            NewEmail = $strResolvedUser.NewEmail
            UPN = $strResolvedUser.UPN
        } 
    }
    $intProgressStatus ++
}
#   export to file
$psobjUnresolvedUsers | ConvertTo-Csv | Out-File $strUnresolvedUserFilePath
$psobjResolvedUsers | ConvertTo-Csv | Out-File $strResolvedUserFilePath
