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

Write-Host "Imported $($arrImportedUsers.Count) users from $($strImportFilePath). Performing data validation" -ForegroundColor Green
#   Perform data validation
$arrUser = @()
$intProgressStatus = 1
$intResolvedUserSuccess = 0
$intResolvedUserFailure = 0
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
    $psobjResolvedUserStatus = @()
    try{
        $arrGetMgUser = Get-MgUser -UserId $arrUser.upn -ErrorAction Stop
        $psobjResolvedUserStatus += [PSCustomObject]@{
            Id = $arrGetMgUser.Id
            DisplayName = $arrGetMgUser.DisplayName
            NewEmail = $arrGetMgUser.Mail
            OldEmail = $arrUser.email
            NewPhone = $arrGetMgUser.MobilePhone
            OldPhone = $arrUser.phone
            UPN = $arrGetMgUser.UserPrincipalName
            Result = "User resolved to Azure AD" 
            AuthMethodEmailSet = $false
            AuthMethodPhoneSet = $false
            RawError = $null
        }
        $intResolvedUserSuccess ++       
    }catch{
        $objError = Get-Error
        $psobjResolvedUserStatus += [PSCustomObject]@{
            Id = $null
            DisplayName = $null
            NewEmail = $null
            OldEmail = $arrUser.mail
            NewPhone = $null
            OldPhone = $arrUser.phone
            UPN = $arrUser.upn
            Result = "Unable to resolve user to Azure AD"
            AuthMethodEmailSet = $false
            AuthMethodPhoneSet = $false
            RawError = $objError
        } 
        $intResolvedUserFailure ++
    }
    $intProgressStatus ++
}
$arrResolvedUsers = $psobjResolvedUserStatus | Where-Object {$_.Result -eq "User resolved to Azure AD"}
$psobjUnresolvedUsers = $psobjResolvedUserStatus | Where-Object {$_.Result -eq "Unable to resolve user to Azure AD"}
Write-Host "Resolved Users: $intResolvedUserSuccess" -ForegroundColor Green
Write-Host "Unresolved Users: $intResolvedUserFailure" -ForegroundColor Red
Write-Host "Setting Authentication Information for $($arrResolvedUsers.Count) users"
#   Set attributes for validated objects
$intProgressStatus = 1
$arrResolvedUser = ""
$intAuthUpdateEmailSuccess = 0
$intAuthUpdateEmailFailure = 0
$intAuthUpdatePhoneSuccess = 0
$intAuthUpdatePhoneFailure = 0
$psobjAuthMethodResults = @()
$psobjAuthMethodResults = $psobjUnresolvedUsers #   This is to ensure that the unresolved users are included in the final output
foreach($arrUser in $arrResolvedUsers){
    $objError = ""
    Write-Progress `
    -Activity "Setting Authentication Information" `
    -Status "$($intProgressStatus) of $($arrResolvedUsers.Count)" `
    -CurrentOperation $intProgressStatus `
    -PercentComplete  (($intProgressStatus / @($arrResolvedUsers).Count) * 100)
    #   set variables internal to the loop
    $arrEmailParams = @()
    $arrEmailParams = @{
        EmailAddress = $arrUser.OldEmail
    }
    $arrPhoneParams = @()
    $arrPhoneParams = @{
        PhoneNumber = "+1 " + $arrUser.OldPhone
        PhoneType = "mobile"
    }
    $id = $arrUser.Id
    $displayName = $arrUser.DisplayName
    $newEmail = $arrUser.NewEmail
    $oldEmail = $arrUser.OldEmail
    $newPhone = $arrUser.NewPhone
    $oldPhone = $arrUser.OldPhone
    $upn = $arrUser.UPN
    $result = $arrUser.Result   
    $authMethodEmailSet = $arrUser.AuthMethodEmailSet
    $authMethodPhoneSet = $arrUser.AuthMethodPhoneSet
    $rawError = $arrUser.RawError
#   Try/Catch - Test Azure AD User Object
    try{
        New-MgUserAuthenticationEmailMethod -UserId $arrResolvedUser.UPN -BodyParameter $arrEmailParams -ErrorAction Stop
        $authMethodEmailSet = $true
        $result += " | Email Authentication Method Set"
        $intAuthUpdateEmailSuccess ++
    }catch{
        $objError = $rawError += Get-Error
        $result += " | Email Authentication Method Not Set"
        $intAuthUpdateEmailFailure ++
    } 
    try{
        New-MgUserAuthenticationPhoneMethod -UserId $arrResolvedUser.UPN -BodyParameter $arrPhoneParams -ErrorAction Stop
        $authMethodPhoneSet = $true
        $result += " | Phone Authentication Method Set"
        $intAuthUpdatePhoneSuccess ++
    }catch {
        $objError = $rawError += Get-Error
        $result += " | Phone Authentication Method Not Set"
        $intAuthUpdatePhoneFailure ++
    }
    $psobjAuthMethodResults += [PSCustomObject]@{
        Id = $id
        DisplayName = $displayName
        NewEmail = $newEmail
        OldEmail = $oldEmail
        NewPhone = $newPhone
        OldPhone = $oldPhone
        UPN = $upn
        Result = $result
        AuthMethodEmailSet = $authMethodEmailSet  
        AuthMethodPhoneSet = $authMethodPhoneSet
        RawError = $rawError
    } 
    $intProgressStatus ++
}
Write-Host "Email Authentication Method Suceeded for " + $intAuthUpdateEmailSuccess + " Users." -ForegroundColor Green
Write-Host "Phone Authentication Method Suceeded for " + $intAuthUpdatePhoneSuccess + " Users." -ForegroundColor Green
Write-Host "Email Authentication Method Failed for " + $intAuthUpdateEmailFailure + " Users." -ForegroundColor Red
Write-Host "Phone Authentication Method Suceeded for " + $intAuthUpdatePhoneSuccess + " Users." -ForegroundColor Green
Write-Host "Phone Authentication Method Failed for " + $intAuthUpdatePhoneFailure + " Users." -ForegroundColor Red
Write-Host "Total successes: " + ($intAuthUpdateEmailSuccess + $intAuthUpdatePhoneSuccess) -ForegroundColor Green
Write-Host "Total failures: " + ($intAuthUpdateEmailFailure + $intAuthUpdatePhoneFailure) -ForegroundColor Red
Write-Host "Exporting results to CSV file. "
#   export to file
$dateNow = $null
$strFilePathDate = $null
$strFinalStatusOutput = $null
$dateNow = Get-Date 
$strFilePathDate = $dateNow.ToString("yyyyMMddhhmm")
$strFinalStatusOutput = $strExportDirPath + "BatchSSPR_AuthMethodSetResults" + $strFilePathDate + ".csv"
$psobjAuthMethodResults | ConvertTo-Csv | Out-File $strFinalStatusOutput
Write-Host "Export complete. " -ForegroundColor Green
Write-Host "See " + $strFinalStatusOutput + " for a detailed output."$ -ForegroundColor Red -BackgroundColor Yellow