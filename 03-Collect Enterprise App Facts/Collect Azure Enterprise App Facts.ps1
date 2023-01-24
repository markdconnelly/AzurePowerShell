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
    $strEntAppObjectID = ""
    $strAppRegObjectID = ""
    $strAppDisplayName = ""
    $strServicePrincipalNames = ""
    $strServicePrincipalType = ""
    $strAppID = ""
    $strAppOrgID = ""
    $strAppOwnerRaw = ""
    $psobjAPIOutput =@()
    $strAPIRaw = ""
    $strAPIKnownClientApps = ""
    $strAPIPreAuthedApps = ""
    $strAPIAcceptedMappedClaims = ""
    $strAPIOauth2PermissionScopesRaw = ""
    $strAppRoles = ""
    $Oauth2PermissionScopesRaw = ""
    $psobjEntAppCertOutput = @()
    $arrEntAppCertificateRaw = @()
    $arrAppRegCertificateRaw = @()
    $psobjEntAppSecretOutput = @()
    $arrAppRegSecretRaw = @()
    $strRequiredResourceAccess = ""
    $strAppMembershipRaw = ""
    $strEntAppCreatedObjects = ""
    $strPreferredSSOMode = ""
    $strAppPublisherDomain = ""
    $arrAppWebRaw = @()
    $strAppWebHomePageURL = ""
    $strAppWebLogoutURL = ""
    $strAppWebRedirectURI = ""
    $strAppWebRedirectURISettings = ""
    $strApPWebImplicitSettingsRaw = ""
    $strAppWebHomePageURL = ""
    $strAppSignInAudience = ""
    $strSAMLSSOSettings = ""
    $strPrefferedTokenSignThumbprint = ""
    $strIdentifierURI = ""
    $strSAMLMetadataURL = ""
    $strSignInURL = ""
    $strLogoutURL = ""
    $strReplyURLs
    $strNotificationEmail = ""
    $strTokenEncryptionKeyID = ""
    $strTokenIssuancePolicy = ""
    $strTokenLifetimePolicy = ""
    $strGroupMembershipClaims = ""
    $strOptionalClaimsRaw = ""
    $strClaimsMappingPolicy = ""
    $strDelegatedPermissionClassification = ""
    $strEndpoints = ""
    $strFederatedIdentityCredentials = ""
    $psobjEntAppListOutput = @()
    $arrAAD_Applications = @()  
    $strEntAppDirObjFacts = ""
    $strAppRegDirObjFacts = ""
    $strAppFacts = ""
    $strSrvPrcFacts = ""
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
            $strEntAppObjectID = $app.Id
            $strAppID = $app.AppId

            #   Enterprise applications are Applications, Directory Objects, and Service Principals. Because of this, we collect 4 arrays for 
            #   each object type per application. We also do the AppFacts first because App Registrations have unique object IDs that we need
            #   to extract before getting the Directory Objects
            $strAppFacts = Get-MgApplication -Filter "AppId eq '$strAppID'"
            $strAppRegObjectID = $strAppFacts.Id
            $strSrvPrcFacts = Get-MgServicePrincipal -Filter "Id eq '$strEntAppObjectID'"
            $strEntAppDirObjFacts = Get-MgDirectoryObject -DirectoryObjectId $strEntAppObjectID
            $strAppRegDirObjFacts = Get-MgDirectoryObject -DirectoryObjectId $strAppRegObjectID
            $strEntAppDirObjFacts = $strEntAppDirObjFacts.AdditionalProperties
            $strAppRegDirObjFacts = $strAppRegDirObjFacts.AdditionalProperties

#$Fix extraction strings after this

            
           

            $strServicePrincipalNames = ""
            $strServicePrincipalType = ""

            $strAppOrgID = ""
            $strAppOwnerRaw = ""
            $psobjAPIOutput =@()
            $strAPIRaw = ""
            $strAPIKnownClientApps = ""
            $strAPIPreAuthedApps = ""
            $strAPIAcceptedMappedClaims = ""
            $strAPIOauth2PermissionScopesRaw = ""
            $strAppRoles = ""
            $Oauth2PermissionScopesRaw = ""
            $psobjEntAppCertOutput = @()
            $arrEntAppCertificateRaw = @()
            $arrAppRegCertificateRaw = @()
            $psobjEntAppSecretOutput = @()
            $arrAppRegSecretRaw = @()
            $strRequiredResourceAccess = ""
            $strAppMembershipRaw = ""
            $strEntAppCreatedObjects = ""
            $strPreferredSSOMode = ""
            $strAppPublisherDomain = ""
            $arrAppWebRaw = @()
            $strAppWebHomePageURL = ""
            $strAppWebLogoutURL = ""
            $strAppWebRedirectURI = ""
            $strAppWebRedirectURISettings = ""
            $strApPWebImplicitSettingsRaw = ""
            $strAppWebHomePageURL = ""
            $strAppSignInAudience = ""
            $strSAMLSSOSettings = ""
            $strPrefferedTokenSignThumbprint = ""
            $strIdentifierURI = ""
            $strSAMLMetadataURL = ""
            $strSignInURL = ""
            $strLogoutURL = ""
            $strReplyURLs
            $strNotificationEmail = ""
            $strTokenEncryptionKeyID = ""
            $strTokenIssuancePolicy = ""
            $strTokenLifetimePolicy = ""
            $strGroupMembershipClaims = ""
            $strOptionalClaimsRaw = ""
            $strClaimsMappingPolicy = ""
            $strDelegatedPermissionClassification = ""
            $strEndpoints = ""
            $strFederatedIdentityCredentials = ""
            $psobjEntAppListOutput = @()

#up to this - see below for old content




















































































































            #   Set attributes that don't require further parsing
            
            $strPreferredSSOMode = $strEntAppDirObjFacts.PreferredSingleSignOnMode
            $strPrefferedTokenSignThumbprint = $strDirObjFacts.preferredTokenSigningKeyThumbprint | Out-String
            $strAppSignInAudience = $strDirObjFacts.signInAudience
            $strIdentifierURI = $strAppFacts.IdentifierUris | Out-String
            $strSAMLMetadataURL = $strAppFacts.SamlMetadataUrl

            #   extract and parse the sub objects of the web element
            $arrAppWebRaw = $strAppFacts.Web
            $strSignInURL = $arrAppWebRaw.RedirectUris | Out-String
            $strLogoutURL = $arrAppWebRaw.LogoutUrl 

            #   extract and parse the Application owenership element
            $strAppOwnerRaw = Get-MgServicePrincipalOwner -ServicePrincipalId $strAppObjectID
            $arrAppOwnerParsed = $strAppOwnerRaw.displayName | Out-String

            #   extract and parse the Application membership element
            $strAppMembershipRaw = Get-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $strAppObjectID
            $strAppMembershipParsed = $strAppMembershipRaw.PrincipalDisplayName | Out-String

            #   extract and parse the member of element
            $strAppMemberOfRaw = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $strAppObjectID
            $strAppMemberOfParsed = $strAppMemberOfRaw.ResourceDisplayName | Out-String

            #   extract and parse the sub objects of the Secret element
            $arrAppRegSecretRaw = $strAppFacts.PasswordCredentials
            $arrThisAppSecrets = @()
            $psobjThisAppSecrets = @()
            foreach($secret in $arrAppRegSecretRaw){
                #   set loop variables that need to be reset for each iteration to calculate days to expiration
                $loopVarEndDate = ""
                $loopVarDaysToExpire = ""
                $loopVarEndDate = $secret.EndDateTime
                $loopVarDaysToExpire = New-TimeSpan -Start $dateNow -End $loopVarEndDate

                #   PSObj to store the full secret table
                $psobjEntAppSecretOutput += [PSCustomObject]@{
                    KeyName = $secret.DisplayName 
                    SecretID = $secret.KeyId
                    StartDate = $secret.StartDateTime
                    EndDate = $secret.EndDateTime
                    DaysToExpire = $loopVarDaysToExpire.Days
                    AppDisplayName = $strAppDisplayName
                    AppObjectID = $strAppObjectID
                } ##[PSCustomObject]@{}  

                #   PSObj to store a table of this specific apps secret ID and name
                $psobjThisAppSecrets += [PSCustomObject]@{
                    KeyName = $secret.DisplayName 
                    SecretID = $secret.KeyId
                } ##[PSCustomObject]@{} 
            }
            $arrThisAppSecrets = $psobjThisAppSecrets | Out-String

            #   extract and parse the sub objects of the Certificate elements
            $arrEntAppCertificateRaw = $strSrvPrcFacts.KeyCredentials
            $arrAppRegCertificateRaw = $strAppFacts.KeyCredentials
            $arrThisAppCertificates = @()




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
            $arrThisAppCertificates = $psobjEntAppCertOutput.CertID | Out-String



            
            
























































































































            #   extract and parse the sub objects of the Certificate elements
            $arrAppCertificateRaw = $strSrvPrcFacts.KeyCredentials
            $arrAppRegCertificateRaw = $strAppFacts.KeyCredentials
            $arrThisAppCertificates = @()




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
            $arrThisAppCertificates = $psobjEntAppCertOutput.CertID | Out-String

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
                Secrets = $arrThisAppSecrets
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