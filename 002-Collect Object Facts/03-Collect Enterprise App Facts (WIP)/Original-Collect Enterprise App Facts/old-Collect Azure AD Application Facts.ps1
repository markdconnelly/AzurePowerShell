#requires -Module Microsoft.Graph.Applications, Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore, Az.KeyVault
################################################################################################################################################
#################################################### <Description> #############################################################################
Write-Host "Application Name: Collect Azure AD Application Facts" -ForegroundColor White -BackgroundColor Black
Write-Host "Author: Mark Connelly" -ForegroundColor White -BackgroundColor Black
Write-Host "Version: 1.0" -ForegroundColor White -BackgroundColor Black
Write-Host "Date: 12-31-22" -ForegroundColor White -BackgroundColor Black
Write-Host "Purpose: This script is built to collect a full collection table output of Azure Enterprise Applications facts. " -ForegroundColor White -BackgroundColor Black
#################################################### </Description> ############################################################################
################################################################################################################################################


################################################################################################################################################
#################################################### <Variables> ###############################################################################
#region variables    

    #################################################### <System Variables> ####################################################################
    #region system variables
    Write-Host "Setting system variables" -ForegroundColor Green -BackgroundColor Black
    #Set file path where tables and logs are stored and start transciption
    $strFilePathOut = "C:\Temp\"
    Write-Host "File path set to " $strFilePathOut -ForegroundColor Green -BackgroundColor Black
    $dateNow = Get-Date 
    $strFilePathDate = $dateNow.ToString("yyyyMMddhhmm")
    $strLogOutputPath = $strFilePathOut + "PowerShellLog_" + $strFilePathDate + ".txt"
    $strEntAppOutputPath = $strFilePathOut + "EnterpriseApps_" + $strFilePathDate + ".csv"
    $strEntAppCertOutputPath = $strFilePathOut + "EnterpriseAppCerts_" + $strFilePathDate + ".csv"
    $strEntAppSecretOutputPath = $strFilePathOut + "EnterpriseAppSecrets_" + $strFilePathDate + ".csv"
    Write-Host "Log files will be saved to " $strLogOutputPath -ForegroundColor Green -BackgroundColor Black
    Write-Host "The Enterprise Application Table will be saved to " $strEntAppOutputPath -ForegroundColor Green -BackgroundColor Black
    Write-Host "The Enterprise Application Certificate Table will be saved to " $strEntAppCertOutputPath -ForegroundColor Green -BackgroundColor Black
    Write-Host "The Enterprise Application Secret Table will be saved to " $strEntAppSecretOutputPath -ForegroundColor Green -BackgroundColor Black

    Start-Transcript -Path $strLogOutputPath
    
    #Set Graph authentication, keys and permission scopes
    #Note: There are many ways to store/retrieve client secrets
    #Encypted key files, powershell secret management module, azure key vault, etc
    Write-Host "Obtaining an access token for the Graph API" -ForegroundColor White -BackgroundColor Black
    $strClientID = "(Your Application (Client) ID Here)"
    $strTenantID = "(Your Tenant ID Here)"
    $strClientSecret = "(Your Client Secret Here)"
    $strAPI_URI = "https://login.microsoftonline.com/$strTenantID/oauth2/token"
    $arrAPI_Body = @{
        grant_type = "client_credentials"
        client_id = $strClientID
        client_secret = $strClientSecret
        resource = "https://graph.microsoft.com"
    }
    $objAccessTokenRaw = Invoke-RestMethod -Method Post -Uri $strAPI_URI -Body $arrAPI_Body -ContentType "application/x-www-form-urlencoded"
    if($objAccessTokenRaw){
        Write-Host "Obtained Access Token" -ForegroundColor Green -BackgroundColor Black
    }else {
        Write-Host "Unable to Obtrain an Access Token" -ForegroundColor Red -BackgroundColor Black
    }
    $objAccessToken = $objAccessTokenRaw.access_token
    Write-Host "System variables set" -ForegroundColor Black -BackgroundColor Green
    #endregion system variables
    #################################################### </System Variables> ###################################################################

    #################################################### <Enterprise Application Variables> ####################################################
    #region Enterprise Application Variables
    Write-Host "Setting Enterprise Application variables to null" -ForegroundColor Green -BackgroundColor Black
    #Set enterprise application variables to blank to ensure sequence of operations    
    $psobjEntAppListOutput = @()
    $arrAAD_Applications = @()
    $arrAppRegSecretRaw = @()
    $arrAppRegCertificateRaw = @()
    $arrAppWebRaw = @()
    $strDirObjFacts = ""
    $strAppFacts = ""
    $strSrvPrcFacts = ""
    $strAppDisplayName = ""
    $strAppObjectID = ""
    $strAppID = ""
    $strAppMembershipRaw = ""
    $strAppOwnerRaw = ""
    $arrAppOwnerParsed = @()
    $strAppSignInAudience = ""
    #endregion Enterprise Application Variables
    #################################################### </Enterprise Application Variables> ###################################################

    #################################################### <Enterprise Application Certificate Variables> ########################################
    #region Enterprise Application Certificate Variables
    Write-Host "Setting Enterprise Application Certificate variables to null" -ForegroundColor Green -BackgroundColor Black
    $psobjEntAppCertOutput = @()
    $arrAppCertificateRaw = @()
    $arrAppRegCertificateRaw = @()
    #endregion Enterprise Application Certificate Variables
    #################################################### </Enterprise Application Certificate Variables> #######################################

    #################################################### <Enterprise Application Secret Variables> #############################################
    #region Enterprise Application Secret Variables
    Write-Host "Setting Enterprise Application Secret variables to null" -ForegroundColor Green -BackgroundColor Black
    $psobjEntAppSecretOutput = @()
    $arrAppRegSecretRaw = @()
    #endregion Enterprise Application Secret Variables
    #################################################### </Enterprise Application Secret Variables> ############################################

    #################################################### <Enterprise Application SSO Variables> ################################################
    #region Enterprise Application SSO Variables
    Write-Host "Setting Enterprise Application SSO variables to null" -ForegroundColor Green -BackgroundColor Black
    $strPreferredSSOMode = ""
    $strPrefferedTokenSignThumbprint = ""
    $strIdentifierURI = ""
    $strSAMLMetadataURL = ""
    $strSignInURL = ""
    $strLogoutURL = ""
    #endregion Enterprise Application SSO Variables
    #################################################### </Enterprise Application SSO Variables> ###############################################
Write-Host "Variables cleared" -ForegroundColor White -BackgroundColor Black
#endregion variables     
#################################################### </Variables> ##############################################################################
################################################################################################################################################


################################################################################################################################################
#################################################### <Functions> ###############################################################################
#region Functions
Write-Host "Beginning script functions" -ForegroundColor White -BackgroundColor Black
    #################################################### <Module Load> #########################################################################
    #region module load    
        Try{
            Connect-Graph -Accesstoken $objAccessToken
            Start-Sleep -Seconds 60
        }catch{
            Write-Host "Unable to connect to the Microsoft Graph API" -ForegroundColor Red -BackgroundColor Black
        }
    #endregion module load     
    #################################################### </Module Load> ########################################################################

    #################################################### <Build Enterprise App Table> ############################################################
    #region Build Enterprise App Table 
        
        #Get a full list of Azure AD Enterprise Applications
        Write-Host "Obtaining full array of Azure Enterprise Applications" -ForegroundColor Green -BackgroundColor Black
        $arrAAD_Applications = Get-MgServicePrincipal -All:$true | Where-Object {$_.Tags -eq "WindowsAzureActiveDirectoryIntegratedApp"}

        #loop through apps and build a normalized table
        Write-Host "Begin loop through applications array" -ForegroundColor Green -BackgroundColor Black
        foreach ($app in $arrAAD_Applications) {
            Write-Host "Collecting core information for " + $app.DisplayName -ForegroundColor Green -BackgroundColor Black
            $strAppDisplayName = $app.DisplayName 
            $strAppObjectID = $app.Id
            $strAppID = $app.AppId

            $strDirObjFacts =  Get-MgDirectoryObject -DirectoryObjectId $strAppObjectID 
            $strAppFacts = Get-MgApplication -Filter "AppId eq '$strAppID'"
            $strSrvPrcFacts = Get-MgServicePrincipal -Filter "Id eq '$strAppObjectID'"
            $strDirObjFacts = $strDirObjFacts.AdditionalProperties
            
            #set application specific array of secrets and certificates (These variables should clear and re-populate for each app - ie. in each loop)
            $arrThisAppSecretIDs = @()
            $arrThisAppCertificateIDs = @()

            #extract MG Directory Object Json
            $strPreferredSSOMode = $strDirObjFacts.PreferredSingleSignOnMode
            $strPrefferedTokenSignThumbprint = $strDirObjFacts.preferredTokenSigningKeyThumbprint | Out-String
            $strAppSignInAudience = $strDirObjFacts.signInAudience

            #extract MG Service Principal Object Json
            $arrAppCertificateRaw = $strSrvPrcFacts.KeyCredentials
    
            #extrat MG Application Object Json
            $strIdentifierURI = $strAppFacts.IdentifierUris | Out-String
            $strSAMLMetadataURL = $strAppFacts.SamlMetadataUrl
            $arrAppWebRaw = $strAppFacts.Web
            $strSignInURL = $arrAppWebRaw.RedirectUris | Out-String
            $strLogoutURL = $arrAppWebRaw.LogoutUrl 
            $arrAppRegSecretRaw = $strAppFacts.PasswordCredentials
            $arrAppRegCertificateRaw = $strAppFacts.KeyCredentials
            
            #extract facts via specific commands
            $strAppMembershipRaw = Get-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $strAppObjectID
            $strAppOwnerRaw = Get-MgServicePrincipalOwner -ServicePrincipalId $strAppObjectID
            $arrAppOwnerParsed = $strAppOwnerRaw.displayName | Out-String
            $strAppMembershipParsed = $strAppMembershipRaw.PrincipalDisplayName | Out-String
            $strAppMemberOfRaw = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $strAppObjectID
            $strAppMemberOfParsed = $strAppMemberOfRaw.ResourceDisplayName | Out-String
            foreach($secret in $arrAppRegSecretRaw){
                $loopVarEndDate = ""
                $loopVarDaysToExpire = ""
                $loopVarEndDate = $secret.EndDateTime
                $loopVarDaysToExpire = New-TimeSpan -Start $dateNow -End $loopVarEndDate
                $psobjEntAppSecretOutput += [PSCustomObject]@{
                    KeyName = $secret.DisplayName 
                    SecretID = $secret.KeyId
                    StartDate = $secret.StartDateTime
                    EndDate = $secret.EndDateTime
                    DaysToExpire = $loopVarDaysToExpire.Days
                    AppDisplayName = $strAppDisplayName
                    AppObjectID = $strAppObjectID
                } ##[PSCustomObject]@{}   
            }
            $arrThisAppSecretIDs = $varEntAppSecretOutput.SecretID | Out-String
            foreach($cert in $arrAppRegCertificateRaw){
                $loopVarEndDate = ""
                $loopVarDaysToExpire = ""
                $loopVarEndDate = $cert.EndDateTime
                $loopVarDaysToExpire = New-TimeSpan -Start $dateNow -End $loopVarEndDate
                $psobjEntAppCertOutput += [PSCustomObject]@{
                    CertName = $cert.DisplayName
                    CertID = $cert.KeyId
                    StartDate = $cert.StartDateTime
                    EndDate = $cert.EndDateTime
                    DaysToExpire = $loopVarDaysToExpire.Days
                    Type = "App Registration"
                    Usage = $cert.Usage
                    Thumbprint = $cert.CustomKeyIdentifier
                    AppDisplayName = $strAppDisplayName
                    AppObjectID = $strAppObjectID
                } ##[PSCustomObject]@{}   
            }
            foreach($cert in $arrAppCertificateRaw){
                $loopVarEndDate = ""
                $loopVarDaysToExpire = ""
                $loopVarEndDate = $cert.EndDateTime
                $loopVarDaysToExpire = New-TimeSpan -Start $dateNow -End $loopVarEndDate
                $psobjEntAppCertOutput += [PSCustomObject]@{
                    CertName = $cert.DisplayName
                    CertID = $cert.KeyId
                    StartDate = $cert.StartDateTime
                    EndDate = $cert.EndDateTime
                    DaysToExpire = $loopVarDaysToExpire.Days
                    Type = "Enterprise Application"
                    Usage = $cert.Usage
                    Thumbprint = $cert.CustomKeyIdentifier
                    AppDisplayName = $strAppDisplayName
                    AppObjectID = $strAppObjectID
                } ##[PSCustomObject]@{}  
            }
            $arrThisAppCertificateIDs = $psobjEntAppCertOutput.CertID | Out-String

            #create/append PS Custom Object to store a table output of the enterprise application list
            $psobjEntAppListOutput += [PSCustomObject]@{               
                DisplayName = $strAppDisplayName
                ObjectID = $strAppObjectID
                AppID = $strAppID
                Owner = $arrAppOwnerParsed
                MembersAssigned = $strAppMembershipParsed
                MemberOf = $strAppMemberOfParsed
                SSOMode = $strPreferredSSOMode
                TokenThumbprint = $strPrefferedTokenSignThumbprint
                SignInAudience = $strAppSignInAudience
                MetadataURL = $strSAMLMetadataURL
                Identifier = $strIdentifierURI
                SignInURL = $strSignInURL
                LogoutURL = $strLogoutURL
                SecretsIDs = $arrThisAppSecretIDs
                CertificateIDs = $arrThisAppCertificateIDs
            } ##[PSCustomObject]@{}
        }
    #endregion Build Enterprise App Table    
    #################################################### </Build Enterprise App Table> #########################################################

    #################################################### </Output files> #########################################################
    #region export to file
        Write-Host "Beginning file export process" -ForegroundColor Green -BackgroundColor Black
        $psobjEntAppListOutput | ConvertTo-Csv | Out-File $strEntAppOutputPath
        Write-Host "The Enterprise Application Table is stored at " + $strEntAppOutputPath -ForegroundColor Green -BackgroundColor Black
        $psobjEntAppSecretOutput | ConvertTo-Csv | Out-File $strEntAppSecretOutputPath
        Write-Host "The Enterprise Application Secret Table is stored at " + $strEntAppSecretOutputPath -ForegroundColor Green -BackgroundColor Black
        $psobjEntAppCertOutput | ConvertTo-Csv | Out-File $strEntAppCertOutputPath
        Write-Host "The Enterprise Application Certificate Table is stored at " + $strEntAppCertOutputPath -ForegroundColor Green -BackgroundColor Black
        Stop-Transcript
        Write-Host "Reminder, the log output is available at " + $strLogOutputPath -ForegroundColor Green -BackgroundColor Black
        Disconnect-Graph
        Write-Host "Graph disconnected" + $strLogOutputPath -ForegroundColor Green -BackgroundColor Black
    #endregion Build Enterprise App Table    
    #################################################### </Output files> #########################################################

#################################################### </Functions> ##############################################################################
################################################################################################################################################