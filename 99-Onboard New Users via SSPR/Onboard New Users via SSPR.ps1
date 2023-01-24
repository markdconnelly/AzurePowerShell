#   This script assumes that you are connected to Graph via an Application Registration with "UserAuthenticationMethod.ReadWrite.All"

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
$csvUsersPreRegistered = ""
$csvUsersNotPreRegistered = ""
######################Variables#################

#   This import is critical to the workflow of this script. See the example csv in this folder for details.
#       - CSV "upn" maps to Script $strUser
#       - CSV "email" maps to Script $strEmailAddress
#       - CSV "phone" maps to Script $strPhoneNumber
$arrImportedUsers = Import-Csv -LiteralPath "(Your CSV File Path Here)"

#   Perform data validation
foreach($strUser in $arrImportedUsers){
    try{
        $arrGetMgUser = Get-MgUser -UserId $strUser
        $psobjResolvedUsers += [PSCustomObject]@{
            Id = $arrGetMgUser.Id
            DisplayName = $arrGetMgUser.DisplayName
            NewEmail = $arrGetMgUser.Mail
            ProvidedEmail = $strUser.mail
            UPN = $arrGetMgUser.UserPrincipalName
            ProvidedPhone = $strUser.phone
        } ##[PSCustomObject]@{}        
    }catch{
         $psobjUnresolvedUsers += [PSCustomObject]@{
            ProvidedUsername = $strUser
            ProvidedEmail = $strUser.mail
            ProvidedPhone = $strUser.phone
            FailureReason = "Unable to resolve"
            Id = "N/A"
            DisplayName = "N/A"
            NewEmail = "N/A"
            UPN = "N/A"
        } ##[PSCustomObject]@{} 
    }
}

#   Set attributes for validated objects
foreach($strResolvedUser in $arrResolvedUsers){
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
        $psobjUnresolvedUsers += [PSCustomObject]@{
            ProvidedUsername = $strResolvedUser
            ProvidedEmail = $strResolvedUser.ProvidedEmail
            ProvidedPhone = $strResolvedUser.ProvidedPhone
            FailureReason = "User resolved to Azure AD, but security info was not able to be set"
            Id = $strResolvedUser.Id
            DisplayName = $strResolvedUser.DisplayName
            NewEmail = $strResolvedUser.NewEmail
            UPN = $strResolvedUser.UPN
        } ##[PSCustomObject]@{} 
    }
}


