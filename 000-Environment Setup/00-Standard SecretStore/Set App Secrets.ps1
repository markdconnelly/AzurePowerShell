Install-Module Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore -Scope AllUsers
Register-SecretVault -Name LocalSecretStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
Set-Secret -Name PSAppID -Secret "(Your Application (Client) ID Here)"
Set-Secret -Name PSAppTenantID -Secret "(Your Tenant ID Here)"
Set-Secret -Name PSAppOrganizationName -Secret "(Your Organization Domain Name Here)"
Set-Secret -Name PSAppSecret -Secret "(Your Client Secret Here)"
Set-Secret -Name PSAppCert -Secret "(Your Certificate Here)"
Set-Secret -Name PSAppDisplayName -Secret "(Your Application Display Name Here)"
Set-Secret -Name PSEntAppObjectID -Secret "(Your Application Object ID Here)"
Set-Secret -Name PSMSIDisplayName -Secret "(Your Managed Identity Display Name Here)"
Set-Secret -Name PSMSIObjectID -Secret "(Your Managed Identity Object ID Here)"
Set-Secret -Name ITGlueAPI_URL -Secret "(Your ITGlue API URL Here)"
Set-Secret -Name ITGlueAPI_Key -Secret "(Your ITGlue API Key Here)"

Get-SecretInfo -Vault LocalSecretStore