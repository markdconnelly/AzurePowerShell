#requires -Module Microsoft.Graph.Applications, Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore, Az.KeyVault

#Connect to Azure to get your managed identity variables
Connect-AzAccount
Get-AzUserAssignedIdentity -SubscriptionId "(Your Subscription ID Here)" -Name "(Your Managed Identity Name)" -ResourceGroupName "(Your Managed Identity Resource Group)"


#See what secret store commands are available
Get-Command -Module Microsoft.PowerShell.SecretStore

Register-SecretVault -Name LocalSecretStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault

$KVParams = @{
    AZKVaultName = "(Your Vault Name Here)"
    SubsciptionId = "(Your S"
}
Register-SecretVault -Name AzureAutomationKV -ModuleName Az.KeyVault -VaultParameters $KVParams
Get-SecretVault

Connect-AzAccount
Get-AzUserAssignedIdentity -SubscriptionId "(Your Subscription ID Here)" -Name "(Your Managed Identity Name)" -ResourceGroupName "(Your Managed Identity Resource Group)"