###################### Variables Requiring Input #################
$strImportFilePath = ""
$strExportDirPath = ""
$strImportFilePath = "(Your CSV file path here)"
$strExportDirPath = "(Youre export directory path here)"
###################### Variables Requiring Input #################
#   This import is critical to the workflow of this script. See the example csv in this folder for details. The import in this script, should be the export of 
#   "Bulk Set SSPR Authentication Methods.ps1" script.
$arrImportedUsers = @()
$arrImportedUsers = Import-Csv -LiteralPath $strImportFilePath
Write-Host "Imported $($arrImportedUsers.Count) users from $($strImportFilePath). Reprocessing Authentication Methods." -ForegroundColor Green
#   Perform data validation
$intProgressStatus = 1
$intResolvedUserSuccess = 0
$intResolvedUserFailure = 0
$intAuthUpdatePhoneSuccess = 0
$intAuthUpdatePhoneFailure = 0
$intAuthUpdateEmailSuccess = 0
$intAuthUpdateEmailFailure = 0
$boolResolvedAAD = $null
$boolAuthMethodPhoneSet = $null
$boolAuthMethodEmailSet = $null
$psobjAuthMethodReProcessResults = @()

foreach($arrImportedUser in $arrImportedUsers){
    $objCheckAADError = ""
    $objSetPhoneAuthError = ""
    $objSetEmailAuthError = ""
    $arrGetMgUser = @()
    #   Progress Bar
    Write-Progress `
    -Activity "Reprocessing Authentication Methods" `
    -Status "$($intProgressStatus) of $($arrImportedUsers.Count)" `
    -CurrentOperation $intProgressStatus `
    -PercentComplete  (($intProgressStatus / @($arrImportedUsers).Count) * 100)
    #   If the user was previously not found in Azure AD, try to resolve them again.
    if($arrImportedUser.AADUser = $false){
        try {
            $arrGetMgUser = Get-MgUser -UserId $arrImportedUser.UPN -ErrorAction Stop
            $boolResolvedAAD = $true
            $psobjAuthMethodReProcessResults += [PSCustomObject]@{
                Id = $arrGetMgUser.Id
                DisplayName = $arrGetMgUser.DisplayName
                NewEmail = $arrGetMgUser.Mail
                OldEmail = $arrImportedUser.OldEmail
                NewPhone = $arrGetMgUser.MobilePhone
                OldPhone = $arrImportedUser.OldPhone
                UPN = $arrGetMgUser.UserPrincipalName
                Result = "User resolved to Azure AD"
                AADUser = $boolResolvedAAD
                AuthMethodEmailSet = $arrImportedUser.AuthMethodEmailSet
                AuthMethodPhoneSet = $arrImportedUser.AuthMethodPhoneSet
                RawError = $null
            }
            $boolResolvedAAD = $true
            Write-Host "User $($arrGetMgUser.UserPrincipalName) resolved to Azure AD." -ForegroundColor Green
            $intResolvedUserSuccess++
        }
        catch {
            $objCheckAADError = $Error[0].Exception.Message
            $psobjAuthMethodReProcessResults += [PSCustomObject]@{
                Id = $arrGetMgUser.Id
                DisplayName = $arrGetMgUser.DisplayName
                NewEmail = $arrGetMgUser.Mail
                OldEmail = $arrImportedUser.OldEmail
                NewPhone = $arrGetMgUser.MobilePhone
                OldPhone = $arrImportedUser.OldPhone
                UPN = $arrGetMgUser.UserPrincipalName
                Result = "User not resolved to Azure AD"
                AADUser = $boolResolvedAAD
                AuthMethodEmailSet = $arrImportedUser.AuthMethodEmailSet
                AuthMethodPhoneSet = $arrImportedUser.AuthMethodPhoneSet
                RawError = $objCheckAADError
            }
            $boolResolvedAAD = $false
            Write-Host "Unable to resolve user $($arrImportedUser.UPN) to Azure AD. Pelase check the UPN to verify that it is valid." -ForegroundColor Red
            $intResolvedUserFailure++
        }
    }
    #   if phone is not set and the user can be resolved to AAD, try to set the phone method again.
    if(($arrImportedUser.AuthMethodPhoneSet = $false) -and ($boolResolvedAAD = $true)){
        $arrPhoneParams = @()
        $arrPhoneParams = @{
            PhoneNumber = "+1 " + $arrPhoneSetUser.OldPhone
            PhoneType = "mobile"
        }
        try {
            New-MgUserAuthenticationPhoneMethod -UserId $arrUser.UPN -BodyParameter $arrPhoneParams -ErrorAction Stop
            $boolAuthMethodPhoneSet = $true
            $psobjAuthMethodReProcessResults += [PSCustomObject]@{
                Id = $arrGetMgUser.Id
                DisplayName = $arrGetMgUser.DisplayName
                NewEmail = $arrGetMgUser.Mail
                OldEmail = $arrImportedUser.OldEmail
                NewPhone = $arrGetMgUser.MobilePhone
                OldPhone = $arrImportedUser.OldPhone
                UPN = $arrGetMgUser.UserPrincipalName
                Result = "Phone method set for user."
                AADUser = $boolResolvedAAD
                AuthMethodEmailSet = $arrImportedUser.AuthMethodEmailSet
                AuthMethodPhoneSet = $boolAuthMethodPhoneSet
                RawError = $null
            }
            Write-Host "Phone Authentication Method set for $($arrImportedUser.UPN) in Azure AD." -ForegroundColor Green
            $intAuthUpdatePhoneSuccess++
        }
        catch {
            $boolAuthMethodPhoneSet = $false
            $objSetPhoneAuthError = $Error[0].Exception.Message
            $psobjAuthMethodReProcessResults += [PSCustomObject]@{
                Id = $arrGetMgUser.Id
                DisplayName = $arrGetMgUser.DisplayName
                NewEmail = $arrGetMgUser.Mail
                OldEmail = $arrImportedUser.OldEmail
                NewPhone = $arrGetMgUser.MobilePhone
                OldPhone = $arrImportedUser.OldPhone
                UPN = $arrGetMgUser.UserPrincipalName
                Result = "Unable to set phone method for user."
                AADUser = $boolResolvedAAD
                AuthMethodEmailSet = $arrImportedUser.AuthMethodEmailSet
                AuthMethodPhoneSet = $boolAuthMethodPhoneSet
                RawError = $objSetPhoneAuthError
            }
            Write-Host "Phone Authentication Method failed to set for $($arrImportedUser.UPN) in Azure AD." -ForegroundColor Red
            $intAuthUpdatePhoneFailure ++
        }
    }
    #   if email is not set and the user can be resolved to AAD, try to set the phone method again.
    if(($arrImportedUser.AuthMethodPhoneSet = $false) -and ($boolResolvedAAD = $true)){
        $arrEmailParams = @()
        $arrEmailParams = @{
            EmailAddress = $arrImportedUser.OldEmail
        }
        try {
            New-MgUserAuthenticationEmailMethod -UserId $arrImportedUser.UPN -BodyParameter $arrEmailParams -ErrorAction Stop
            $boolAuthMethodEmailSet = $true
            $psobjAuthMethodReProcessResults += [PSCustomObject]@{
                Id = $arrGetMgUser.Id
                DisplayName = $arrGetMgUser.DisplayName
                NewEmail = $arrGetMgUser.Mail
                OldEmail = $arrImportedUser.OldEmail
                NewPhone = $arrGetMgUser.MobilePhone
                OldPhone = $arrImportedUser.OldPhone
                UPN = $arrGetMgUser.UserPrincipalName
                Result = "Email authentication set."
                AADUser = $boolResolvedAAD
                AuthMethodEmailSet = $boolAuthMethodEmailSet
                AuthMethodPhoneSet = $boolAuthMethodPhoneSet
                RawError = $null
            }
            Write-Host "Email Authentication Method set for $($arrImportedUser.UPN) in Azure AD." -ForegroundColor Green
            $intAuthUpdateEmailSuccess++
        }
        catch {
            $objSetEmailAuthError = $Error[0].Exception.Message
            $boolAuthMethodEmailSet = $false
            $psobjAuthMethodReProcessResults += [PSCustomObject]@{
                Id = $arrGetMgUser.Id
                DisplayName = $arrGetMgUser.DisplayName
                NewEmail = $arrGetMgUser.Mail
                OldEmail = $arrImportedUser.OldEmail
                NewPhone = $arrGetMgUser.MobilePhone
                OldPhone = $arrImportedUser.OldPhone
                UPN = $arrGetMgUser.UserPrincipalName
                Result = "Unable to set email method for user."
                AADUser = $boolResolvedAAD
                AuthMethodEmailSet = $boolAuthMethodEmailSet
                AuthMethodPhoneSet = $boolAuthMethodPhoneSet
                RawError = $objSetEmailAuthError
            }
            Write-Host "Email Authentication Method failed to set for $($arrImportedUser.UPN) in Azure AD." -ForegroundColor Red
            $intAuthUpdateEmailFailure ++
        }
    }
    $intProgressStatus ++
}
Write-Host "Succesfully set Phone Authentication Information for $($intAuthUpdatePhoneSuccess) Users." -ForegroundColor Green
Write-Host "Succesfully set Email Authentication Information for $($intAuthUpdateEmailSuccess) Users." -ForegroundColor Green
Write-Host "Failed to set Email Authentication Information for $($intAuthUpdateEmailFailure) Users." -ForegroundColor Red
Write-Host "Failed to set Phone Authentication Information for $($intAuthUpdatePhoneFailure) Users." -ForegroundColor Red
Write-Host "Exporting results to CSV file. "
#   export to file
$dateNow = $null
$strFilePathDate = $null
$strOperationResultsOutput = $null
$dateNow = Get-Date 
$strFilePathDate = $dateNow.ToString("yyyyMMddhhmm")
$strOperationResultsOutput = $strExportDirPath + "BatchSSPR_Reprocess_AuthMethodSetResults" + $strFilePathDate + ".csv"
$psobjAuthMethodReProcessResults | ConvertTo-Csv | Out-File $strOperationResultsOutput
Write-Host "Export complete. " -ForegroundColor Green
Write-Host "See " + $strOperationResultsOutput + " for a detailed output."$ -ForegroundColor Red -BackgroundColor Yellow
