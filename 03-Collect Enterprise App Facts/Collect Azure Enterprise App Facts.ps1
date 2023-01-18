#################################################### <Variables> ###############################################################################
#region variables  
<#
Attributes:
    DirObjEntApp Facts: (Get-MgDirectoryObject $AppRegObjectID)
        - appId
        - displayName
        - identifierUris
        - publisherDomain
        - signInAudience
        - api
            - knownClientApplications
            - preAuthorizedApplications
            - oauth2PermissionScopes
                - adminConsentDescription
                - adminConsentDisplayName
                - id
                - isEnabled
                - type
                - userConsentDescription
                - userConsentDisplayName
                - value
        - appRoles
            - allowedMemberTypes
            - description
            - displayName
            - id
            - isEnabled
            - origin (example value was Application )
        - keyCredentials (Contains app certificates only)
            - displayName
            - endDateTime
            - keyId
            - startDateTime
            - type (Example = AsymmetricX509Cert)
            - usage
        - passwordCredentials (Contains app secrets)
            - displayName
            - endDateTime
            - keyId
            - startDateTime
        - publicClient
            - redirectUris
        - requiredResourceAccess
            - resourceAppId
            - resourceAccess
                - id
                - type
        - web
            - homePageUrl
            - logoutUrl
            - redirectUris
            - implicitGrantSettings
                - enableAccessTokenIssuance
                - enableIdTokenIssuance
            - redirectUriSettings
    DirObjAppReg Facts: (Get-MgDirectoryObject $EntAppObjectID)
        - appDisplayName
        - appId
        - appOwnerOrganizationId
        - displayName
        - homepage
        - logoutUrl
        - notificationEmailAddresses
        - preferredSingleSignOnMode
        - preferredTokenSigningKeyThumbprint
        - replyUrls
        - servicePrincipalType
        - signInAudience
        - appRoles
            - allowedMemberTypes
            - description
            - displayName
            - id
            - isEnabled
            - origin
        - keyCredentials
            - displayName
            - endDateTime
            - keyId
            - startDateTime
            - type
            - usage
        - oauth2PermissionScopes
            - adminConsentDescription
            - adminConsentDisplayName
            - id
            - isEnabled
            - type
            - userConsentDescription
            - userConsentDisplayName
            - value
    AppReg Facts: (Get-MgApplication $ApplicationID)
        - Api
         - AcceptMappedClaims
         - KnownClientApplications
         - Oauth2PermissionScopes
            - AdminConsentDescription
            - AdminConsentDisplayName
            - Id
            - IsEnabled
            - Type
            - UserConsentDescription
            - UserConsentDisplayName
            - Value
        - AppId
        - AppRoles
            - AllowedMemberTypes
            - Description
            - DisplayName
            - Id
            - IsEnabled
            - Origin
            - Value
        - DisplayName
        - GroupMembershipClaims
        - Id
        - IdentifierUris
        - keyCredentials (Contains app certificates only)
            - displayName
            - endDateTime
            - keyId
            - startDateTime
            - type (Example = AsymmetricX509Cert)
            - usage
        - OptionalClaims
            - AccessToken
            - IdToken
            - Saml2Token
        - Owners
        - passwordCredentials (Contains app secrets)
            - displayName
            - endDateTime
            - keyId
            - startDateTime
        - PublicClient
            - RedirectUris
        - requiredResourceAccess
            - resourceAppId
            - resourceAccess
                - id
                - type
        - SamlMetadataUrl
        - SignInAudience
        - TokenEncryptionKeyId
        - TokenIssuancePolicies
        - Web
            - HomePageUrl
            - ImplicitGrantSettings
                - EnableAccessTokenIssuance
                - EnableIdTokenIssuance
            - LogoutUrl
            - RedirectUris
    EntApp Facts: (Get-MgServicePrincipal $EntAppObjectID)
        - AppDisplayName
        - AppId
        - AppOwnerOrganizationId
        - AppRoleAssignedTo
        - AppRoleAssignmentRequired
        - AppRoleAssignments
        - AppRoles
            - AllowedMemberTypes
            - Description
            - DisplayName
            - Id
            - IsEnabled
            - Origin
            - Value
        - ClaimsMappingPolicies
        - CreatedObjects
        - DelegatedPermissionClassifications
        - DisplayName
        - Endpoints
        - FederatedIdentityCredentials
        - Id
        - keyCredentials (Contains sso certificates only)
            - displayName
            - endDateTime
            - keyId
            - startDateTime
            - type (Example = AsymmetricX509Cert)
            - usage
        - LoginUrl
        - LogoutUrl
        - MemberOf
        - NotificationEmailAddresses
        - Oauth2PermissionGrants
        - Oauth2PermissionScopes
            - AdminConsentDescription
            - AdminConsentDisplayName
            - Id
            - IsEnabled
            - Type
            - UserConsentDescription
            - UserConsentDisplayName
            - Value
        - OwnedObjects
        - Owners
        - PreferredSingleSignOnMode
        - PreferredTokenSigningKeyThumbprint
        - ReplyUrls
        - SamlSingleSignOnSettings
            - RelayState
        - ServicePrincipalNames
        - ServicePrincipalType
        - SignInAudience
        - TokenEncryptionKeyId
        - TokenIssuancePolicies
        - TokenLifetimePolicies
#>
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

            #   Set attributes that don't require further parsing
            $strPreferredSSOMode = $strDirObjFacts.PreferredSingleSignOnMode
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

            #extract and parse the Oauth Permissions


            #   extract and parse the sub objects of the Certificate elements
            $arrAppCertificateRaw = $strSrvPrcFacts.KeyCredentials
            $arrAppRegCertificateRaw = $strAppFacts.KeyCredentials
            $arrThisAppCertificates = @()



            #   extract and parse the sub objects of the Secret element
            $arrAppRegSecretRaw = $strAppFacts.PasswordCredentials
            $arrThisAppSecrets = @()


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
            $arrThisAppSecrets = $psobjEntAppSecretOutput | fl DisplayName, SecretID | Out-String



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