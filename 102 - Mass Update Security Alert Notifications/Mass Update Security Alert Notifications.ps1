Connect-Graph -Scopes "SecurityEvents.Read.All, SecurityActions.Read.All, SecurityEvents.Read.All, SecurityIncident.Read.All"

Get-MgSecurityAlert

Connect-ExchangeOnline 

Get-Command -Module ExchangeOnlineManagement