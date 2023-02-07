# Onboard Users via SSPR
This script is used to mass set SSPR registration details for a group of users

The use case for this script, is that you purchased another company, and need to bulk add users to your tenant. It is assumed that valid data can be obtained from the purchased organization. The only methods that are able to be set via the Graph API, is EmailAddress and PhoneNumber. If your SSPR settings require two factors, both of these will need to be set. 

This script includes error handling and logging to check the provided list vs Azure AD, and seperates out users that could not be resolved. It then attempts to set the authentication methods, and if it cannot, it adds those users to the unresolved users table. Both error handling routines include verbose error output. 

After the script has been run, all resolved users will have their methods set and can set their passwords for the first time via the SSPR service without user intervention. 