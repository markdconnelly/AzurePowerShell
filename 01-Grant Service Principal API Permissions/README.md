# PowerShell

The two main locations that our scripts will run are from a developer endpoint, and from an Azure automation account. 

Because we are authenticating in two seperate contexts, we will need to authenticate two different ways. Both service
principals will require the same permissions. This script loops through each permission and adds it to both identitues.