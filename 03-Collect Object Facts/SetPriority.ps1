#   Get raw group membership for admin groups
$arrDomainAdmins = @()
$arrEnterpriseAdmins = @()
$arrSchemaAdmins = @()
$arrAccountOperators = @( )
$arrDomainAdmins = Get-ADGroupMember -Identity "Domain Admins" -Recursive
$arrEnterpriseAdmins = Get-ADGroupMember -Identity "Enterprise Admins" -Recursive
$arrSchemaAdmins = Get-ADGroupMember -Identity "Schema Admins" -Recursive
$arrAccountOperators = Get-ADGroupMember -Identity "Account Operators" -Recursive

#   Correlate admin groups with there regular admin users



#   Get members with job class/code attributes that have been defined for priority users
$arrJobClassCode = @()
$arrJobClassCode = Get-ADUser -Filter "(Your Specific HR Attributes Here)" -Properties *

#  Get members with privileged roles in azure ad
$arrDirectoryRoles = @()
$arrDirectoryRoles = Get-MgDirectoryRole


Get-MgDirectoryRoleMember

#   Correlate and deduplicate list to find a complete list of priority users by user principal name





