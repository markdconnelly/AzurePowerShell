###################### Variables Requiring Input #################
$strImportFilePath = ""
$strExportDirPath = ""
$strPassword = ""
$strImportFilePath = "(Your CSV file path here)"
$strExportDirPath = "(Youre export directory path here)"
$strPassword = "(Default Password Here)" #Read-Host -AsSecureString -Prompt "Enter a default password for all users."
###################### Variables Requiring Input #################

$arrImportedUsers = @()
$arrImportedUsers = Import-Csv -LiteralPath $strImportFilePath
Write-Host "Imported $($arrImportedUsers.Count) users from $($strImportFilePath). Performing data validation" -ForegroundColor Green
#   Progress Bar
Write-Progress `
    -Activity "Cycling Throuh List and Creating Users" `
    -Status "$($intProgressStatus) of $($arrImportedUsers.Count)" `
    -CurrentOperation $intProgressStatus `
    -PercentComplete  (($intProgressStatus / @($arrImportedUsers).Count) * 100)
#   Perform data validation
$arrUser = @()
$psobjBulkAddOutput = @()
$boolAccountEnabled = $null
$intProgressStatus = 1
$intAddUserSuccess = 0
$intAddUserFailure = 0
$hashPassword = @{
    Password = $strPassword
}
foreach($arrUser in $arrImportedUsers){
    $objError = ""
    $strResult = ""
    #   Try/Catch - Add Users
    try {
        New-MgUser `
            -AccountEnabled:$true `
            -DisplayName $arrUser.DisplayName `
            -MailNickname $arrUser.DisplayName `
            -PasswordProfile $hashPassword `
            -UserPrincipalName $arrUser.UserPrincipalName `
            -UsageLocation "US" `
            -ErrorAction Stop
        $boolAccountEnabled = $true
        $strResult = "User added to Azure AD"
        $intAddUserSuccess ++
    }
    catch {
        $objError = Get-Error
        $boolAccountEnabled = $false
        $strResult = "Unable to add user to Azure AD. See error for details."
        $intAddUserFailure ++
    }
    $psobjBulkAddOutput += [PSCustomObject]@{
        UserPrincipalName = $arrUser.UserPrincipalName
        AccountEnabled = $boolAccountEnabled
        DisplayName = $arrGetMgUser.DisplayName
        MailNickName = $arrGetMgUser.DisplayName
        Result = $strResult
        RawError = $objError
    }
    $intProgressStatus ++
}
Write-Host "Finished adding users to Azure AD." 
Write-Host "$($intAddUserSuccess) users added successfully." -ForegroundColor Green
Write-Host "$($intAddUserFailure) users failed to add." -ForegroundColor Red
Write-Host "Exporting results to $($strExportDirPath)\BulkAddUsersToAAD_$(Get-Date -Format yyyyMMdd_HHmmss).csv" -ForegroundColor Green
#   Export results to CSV
$dateNow = $null
$strFilePathDate = $null
$strFinalStatusOutput = $null
$dateNow = Get-Date 
$strFilePathDate = $dateNow.ToString("yyyyMMddhhmm")
$strFinalStatusOutput = $strExportDirPath + "BatchSSPR_AuthMethodSetResults" + $strFilePathDate + ".csv"
$psobjBulkAddOutput | ConvertTo-Csv | Out-File $strFinalStatusOutput
Write-Host "Export complete. " -ForegroundColor Green
Write-Host "See " + $strFinalStatusOutput + " for a detailed output."$ -ForegroundColor Red -BackgroundColor Yellow

New-MgUser `
-AccountEnabled:$true `
-DisplayName "test.Employee5" `
-MailNickname "test.Employee5" `
-PasswordProfile $hashPassword `
-UserPrincipalName "test.employee5@carle.online" `
-UsageLocation "US" `
-ErrorAction Stop