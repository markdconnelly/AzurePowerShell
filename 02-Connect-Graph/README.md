# PowerShell

This script is a standard connection that needs to be made to Graph at the beginning of a session.

To accomplish this task, we gather our application credentials from the secret store (established previously) and create an array with it. We then pass those 
to via Invoke-RestMethod to get an access token. 

After the access token is isolated into a variable, we Connect-Graph with that access token.