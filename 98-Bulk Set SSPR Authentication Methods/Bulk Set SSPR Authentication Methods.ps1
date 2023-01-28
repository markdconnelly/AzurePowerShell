
#   This import is critical to the workflow of this script. See the example csv in this folder for details.
#       - CSV "upn" maps to Script $strUser
#       - CSV "email" maps to Script $strEmailAddress
#       - CSV "phone" maps to Script $strPhoneNumber
$arrImportedUsers = @()
$arrImportedUsers = Import-Csv -LiteralPath $strImportFilePath

Write-Host "Imported $($arrImportedUsers.Count) users from $($strImportFilePath). Performing data validation" -ForegroundColor Green
#   Perform data validation
$arrImportedUser = @()
$intProgressStatus = 1
$intResolvedUserSuccess = 0
$intResolvedUserFailure = 0
$psobjAADUsers = @()
$psobjOperationResults = @()
foreach($arrImportedUser in $arrImportedUsers){
    $objCheckAADError = ""
    $arrGetMgUser = @()
    #   Progress Bar
    Write-Progress `
        -Activity "Checking Users Against Azure" `
        -Status "$($intProgressStatus) of $($arrImportedUsers.Count)" `
        -CurrentOperation $intProgressStatus `
        -PercentComplete  (($intProgressStatus / @($arrImportedUsers).Count) * 100)
    #   Try/Catch - Check If Users Exist in Azure
    try{
        $arrGetMgUser = Get-MgUser -UserId $arrImportedUser.upn -ErrorAction Stop
        $psobjAADUsers += [PSCustomObject]@{
            Id = $arrGetMgUser.Id
            DisplayName = $arrGetMgUser.DisplayName
            NewEmail = $arrGetMgUser.Mail
            OldEmail = $arrImportedUser.email
            NewPhone = $arrGetMgUser.MobilePhone
            OldPhone = $arrImportedUser.phone
            UPN = $arrGetMgUser.UserPrincipalName
            Result = "User resolved to Azure AD"
            AADUser = $true 
            AuthMethodEmailSet = $false
            AuthMethodPhoneSet = $false
            RawError = $null
        }
        $intResolvedUserSuccess ++       
    }catch{
        $objCheckAADError = $Error[0].Exception.Message #Get-Error
        $psobjOperationResults += [PSCustomObject]@{
            Id = $null
            DisplayName = $null
            NewEmail = $null
            OldEmail = $arrImportedUser.mail
            NewPhone = $null
            OldPhone = $arrImportedUser.phone
            UPN = $arrImportedUser.upn
            Result = "Unable to resolve user to Azure AD"
            AADUser = $false
            AuthMethodEmailSet = $false
            AuthMethodPhoneSet = $false 
            RawError = $objCheckAADError
        } 
        $intResolvedUserFailure ++
    }
    $intProgressStatus ++
}
Write-Host "Resolved AAD Users: $intResolvedUserSuccess" -ForegroundColor Green
Write-Host "Unresolved Users: $intResolvedUserFailure" -ForegroundColor Red
Write-Host "Setting Authentication Phone Information for $($psobjAADUsers.Count) users"
#   Set phone attributes for users
$intProgressStatus = 1
$intAuthUpdatePhoneSuccess = 0
$intAuthUpdatePhoneFailure = 0
$arrPhoneSetUser = @()
$psobjPhoneSetResults = @()
foreach($arrPhoneSetUser in $psobjAADUsers){
    $objPhoneSetError = ""
    Write-Progress `
        -Activity "Setting Phone Authentication Information" `
        -Status "$($intProgressStatus) of $($psobjAADUsers.Count)" `
        -CurrentOperation $intProgressStatus `
        -PercentComplete  (($intProgressStatus / $($psobjAADUsers).Count) * 100)
    $arrPhoneParams = @()
    $arrPhoneParams = @{
        PhoneNumber = "+1 " + $arrPhoneSetUser.OldPhone
        PhoneType = "mobile"
    }
    try{
        New-MgUserAuthenticationPhoneMethod -UserId $arrPhoneSetUser.UPN -BodyParameter $arrPhoneParams -ErrorAction Stop
        $psobjPhoneSetResults += [PSCustomObject]@{
            Id = $arrPhoneSetUser.Id
            DisplayName = $arrPhoneSetUser.DisplayName
            NewEmail = $arrPhoneSetUser.NewEmail
            OldEmail = $arrPhoneSetUser.OldEmail
            NewPhone = $arrPhoneSetUser.NewPhone
            OldPhone = $arrPhoneSetUser.OldPhone
            UPN = $arrPhoneSetUser.UPN
            Result = "Phone Authentication Method Set. Email Not Set."
            AuthMethodEmailSet = $false 
            AuthMethodPhoneSet = $true
            RawError = $null
        }
        $intAuthUpdatePhoneSuccess ++
    }catch{
        $objPhoneSetError = $Error[0].Exception.Message #Get-Error

        $psobjOperationResults += [PSCustomObject]@{
            Id = $arrPhoneSetUser.Id
            DisplayName = $arrPhoneSetUser.DisplayName
            NewEmail = $arrPhoneSetUser.NewEmail
            OldEmail = $arrPhoneSetUser.OldEmail
            NewPhone = $arrPhoneSetUser.NewPhone
            OldPhone = $arrPhoneSetUser.OldPhone
            UPN = $arrPhoneSetUser.UPN
            Result = "Unable to resolve user to Azure AD"
            AADUser = $true
            AuthMethodEmailSet = $false
            AuthMethodPhoneSet = $false 
            RawError = $objPhoneSetError
        }
        $intAuthUpdatePhoneFailure ++
    } 
    $intProgressStatus ++
}
Write-Host "Phone Authentication Method Suceeded for $intAuthUpdatePhoneSuccess Users." -ForegroundColor Green
Write-Host "Phone Authentication Method Failed for $intAuthUpdatePhoneFailure Users." -ForegroundColor Red
Write-Host "Setting Authentication Email Information for $($psobjPhoneSetResults.Count) users"
#   Set email attributes for users
$intProgressStatus = 1
$intAuthUpdateEmailSuccess = 0
$intAuthUpdateEmailFailure = 0
$arrEmailSetUser = @()
$intTotalSuccesses = $psobjPhoneSetResults.Count
foreach($arrEmailSetUser in $psobjPhoneSetResults){
    $objEmailSetError = ""
    Write-Progress `
        -Activity "Setting Email Authentication Information" `
        -Status "$($intProgressStatus) of $($psobjPhoneSetResults.Count)" `
        -CurrentOperation $intProgressStatus `
        -PercentComplete  (($intProgressStatus / $($psobjPhoneSetResults).Count) * 100)
    $arrEmailParams = @()
    $arrEmailParams = @{
        EmailAddress = $arrEmailSetUser.OldEmail
    }
    try{
        New-MgUserAuthenticationEmailMethod -UserId $arrEmailSetUser.UPN -BodyParameter $arrEmailParams -ErrorAction Stop
        $psobjOperationResults += [PSCustomObject]@{
            Id = $arrEmailSetUser.Id
            DisplayName = $arrEmailSetUser.DisplayName
            NewEmail = $arrEmailSetUser.NewEmail
            OldEmail = $arrEmailSetUser.OldEmail
            NewPhone = $arrEmailSetUser.NewPhone
            OldPhone = $arrEmailSetUser.OldPhone
            UPN = $arrEmailSetUser.UPN
            Result = "Phone/Email Authentication Method Set."
            AADUser = $true
            AuthMethodEmailSet = $true 
            AuthMethodPhoneSet = $true
            RawError = $null
        }
        $intAuthUpdateEmailSuccess ++
        $intTotalSuccesses ++
    }catch{
        $objEmailSetError = $Error[0].Exception.Message #Get-Error
        $psobjOperationResults += [PSCustomObject]@{
            Id = $arrEmailSetUser.Id
            DisplayName = $arrEmailSetUser.DisplayName
            NewEmail = $arrEmailSetUser.NewEmail
            OldEmail = $arrEmailSetUser.OldEmail
            NewPhone = $arrEmailSetUser.NewPhone
            OldPhone = $arrEmailSetUser.OldPhone
            UPN = $arrEmailSetUser.UPN
            Result = "Phone Information Set. Unable to set Email Authentication Method."
            AADUser = $true
            AuthMethodEmailSet = $false
            AuthMethodPhoneSet = $true 
            RawError = $objEmailSetError
        }
        $intAuthUpdateEmailFailure ++
    } 
    $intProgressStatus ++
}
$intUniqueUserFailures = $psobjOperationResults | Where-Object {$_.AADUser -eq $false -or $_.AuthMethodEmailSet -eq $false -or $_.AuthMethodPhoneSet -eq $false}
Write-Host "Succesfully set Authentication Information for " $intTotalSuccesses " Users." -ForegroundColor Green
Write-Host "Failed to set Email Authentication Information for $intAuthUpdateEmailFailure Users." -ForegroundColor Red
Write-Host "Failed to set Phone Authentication Information for $intAuthUpdatePhoneFailure Users." -ForegroundColor Red
Write-Host "Failed to resolve users to Azure AD for $intResolvedUserFailure Users." -ForegroundColor Red
Write-Host "Unique users with failures: $intUniqueUserFailures"  -ForegroundColor Red
Write-Host "Exporting results to CSV file. "
#   export to file
$dateNow = $null
$strFilePathDate = $null
$strOperationResultsOutput = $null
$dateNow = Get-Date 
$strFilePathDate = $dateNow.ToString("yyyyMMddhhmm")
$strOperationResultsOutput = $strExportDirPath + "BatchSSPR_AuthMethodSetResults" + $strFilePathDate + ".csv"
$psobjOperationResults | ConvertTo-Csv | Out-File $strOperationResultsOutput
Write-Host "Export complete. " -ForegroundColor Green
Write-Host "See " + $strOperationResultsOutput + " for a detailed output."$ -ForegroundColor Red -BackgroundColor Yellow