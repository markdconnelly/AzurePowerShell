#################################################### <Variables> ###############################################################################
#region variables    

    #################################################### <System Variables> ####################################################################
    #region system variables
    #Set file path where tables and logs are stored and start transciption
    $strFilePathOut = "C:\Temp\"
    $dateNow = Get-Date 
    $strFilePathDate = $dateNow.ToString("yyyyMMddhhmm")
    $strLogOutputPath = $strFilePathOut + "PowerShellLog_" + $strFilePathDate + ".txt"
    $strEntAppOutputPath = $strFilePathOut + "EnterpriseApps_" + $strFilePathDate + ".csv"
    $strEntAppCertOutputPath = $strFilePathOut + "EnterpriseAppCerts_" + $strFilePathDate + ".csv"
    $strEntAppSecretOutputPath = $strFilePathOut + "EnterpriseAppSecrets_" + $strFilePathDate + ".csv"

    Start-Transcript -Path $strLogOutputPath
    #################################################### </System Variables> ###################################################################

    #################################################### <Enterprise Application Variables> ####################################################
    #region Enterprise Application Variables
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
    $psobjEntAppCertOutput = @()
    $arrAppCertificateRaw = @()
    $arrAppRegCertificateRaw = @()
    #endregion Enterprise Application Certificate Variables
    #################################################### </Enterprise Application Certificate Variables> #######################################

    #################################################### <Enterprise Application Secret Variables> #############################################
    #region Enterprise Application Secret Variables
    $psobjEntAppSecretOutput = @()
    $arrAppRegSecretRaw = @()
    #endregion Enterprise Application Secret Variables
    #################################################### </Enterprise Application Secret Variables> ############################################

    #################################################### <Enterprise Application SSO Variables> ################################################
    #region Enterprise Application SSO Variables
    $strPreferredSSOMode = ""
    $strPrefferedTokenSignThumbprint = ""
    $strIdentifierURI = ""
    $strSAMLMetadataURL = ""
    $strSignInURL = ""
    $strLogoutURL = ""
    #endregion Enterprise Application SSO Variables
    #################################################### </Enterprise Application SSO Variables> ###############################################
#endregion variables     
#################################################### </Variables> ##############################################################################

#################################################### <Functions> ###############################################################################
#region Functions

#   An API connection to graph is assumed at this point-if you have not connected, please see the "Connect-Graph" folder in this repo
    #################################################### <Build Enterprise App Table> ############################################################
    #region Build Enterprise App Table 
        
        #  To start, we fill an array with the full output of all service principals
        $arrAAD_Applications = Get-MgServicePrincipal -All:$true | Where-Object {$_.Tags -eq "WindowsAzureActiveDirectoryIntegratedApp"}

        #  loop through apps and build a normalized table
        foreach ($app in $arrAAD_Applications) {
            #   The general command Get-MgServicePrincipal primarily has these 3 core facts that we can pivot on for specific sub-commands
            $strAppDisplayName = $app.DisplayName 
            $strAppObjectID = $app.Id
            $strAppID = $app.AppId

            #   Enterprise applications are Applications, Directory Objects, and Service Principals. Because of this, we collect 3 arrays for 
            #   each object type per application. 
            $strDirObjFacts =  Get-MgDirectoryObject -DirectoryObjectId $strAppObjectID 
            $strAppFacts = Get-MgApplication -Filter "AppId eq '$strAppID'"
            $strSrvPrcFacts = Get-MgServicePrincipal -Filter "Id eq '$strAppObjectID'"
            $strDirObjFacts = $strDirObjFacts.AdditionalProperties
            $strPreferredSSOMode = $strDirObjFacts.PreferredSingleSignOnMode
            $strPrefferedTokenSignThumbprint = $strDirObjFacts.preferredTokenSigningKeyThumbprint | Out-String
            $strAppSignInAudience = $strDirObjFacts.signInAudience
            $strIdentifierURI = $strAppFacts.IdentifierUris | Out-String
            $strSAMLMetadataURL = $strAppFacts.SamlMetadataUrl

            #extract the sub objects of the certificates element
            $arrAppCertificateRaw = $strSrvPrcFacts.KeyCredentials
    
            #extract and parse the sub objects of the web element
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

            #set application specific array of secrets and certificates (These variables should clear and re-populate for each app - ie. in each loop)
            $arrThisAppSecretIDs = @()
            $arrThisAppCertificateIDs = @()




            
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
                Secrets = $arrThisAppSecretIDs
                Certificates = $arrThisAppCertificateIDs
            } ##[PSCustomObject]@{}
        }
    #endregion Build Enterprise App Table    
    #################################################### </Build Enterprise App Table> #########################################################

    #################################################### </Output files> #########################################################
    #region export to file
        $psobjEntAppListOutput | ConvertTo-Csv | Out-File $strEntAppOutputPath
        $psobjEntAppSecretOutput | ConvertTo-Csv | Out-File $strEntAppSecretOutputPath
        $psobjEntAppCertOutput | ConvertTo-Csv | Out-File $strEntAppCertOutputPath
        Stop-Transcript
    #endregion Build Enterprise App Table    
    #################################################### </Output files> #########################################################

#################################################### </Functions> ##############################################################################
################################################################################################################################################