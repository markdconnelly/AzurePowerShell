Install-Module Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore -Scope AllUsers
Register-SecretVault -Name LocalSecretStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
Set-Secret -Name PSAppID -Secret "(Your Application (Client) ID Here)"
Set-Secret -Name PSAppTenantID -Secret "(Your Tenant ID Here)"
Set-Secret -Name PSAppSecret -Secret "(Your Client Secret Here)"

Get-SecretInfo -Vault LocalSecretStore