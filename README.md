# PowerShell

This repository is a place to store the various PowerShell scripts that I create along the way. 

For the forseeable future, the majority of my work with PowerShell is going to consist of automation related to Azure and Microsoft 365.
Because of this, most of these scripts will be dependent on the PowerShell Secret Store that is established in: 
    - https://github.com/markdconnelly/PowerShell/tree/main/Standard%20SecretStore

They will also be dependent on having an Enterprise Application with appropriate permissions provisioned, and an Azure Key Vault to store 
keys specific to Azure resources. 

See this link for specific details on creating an Enterprise Application:
    - https://learn.microsoft.com/en-us/graph/auth-v2-service