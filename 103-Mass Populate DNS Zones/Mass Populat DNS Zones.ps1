# This script takes an excel spreadsheet input and creates DNS zones and records in Azure DNS.
# It is assumed that all Azure modules are loaded and that appropriate permissions to modify DNS are in place. 


###################### Variables Requiring Input #################
$strImportFilePath = ""
$strExportDirPath = ""
$strDNS_ResourceGroupName = ""
$strDNS_TTL = ""
$strImportFilePath = "(Your CSV file path here)"
$strExportDirPath = "(Youre export directory path here)"
$strDNS_ResourceGroupName = "(Your DNS Resource Group Name)"
$strDNS_TTL = "(Your TTL in seconds for DNS records here)"
###################### Variables Requiring Input #################

#       - CSV "zone_name" maps to Script $strZoneName  
#       - CSV "record_name" maps to Script $strRecordName
#       - CSV "record_type" maps to Script $strRecordType
#       - CSV "record_value" maps to Script $strRecordValue
$arrImportedDNSRecords = @()
$arrImportedDNSRecords = Import-Csv -LiteralPath $strImportFilePath | Sort-Object -Property zone_name, record_name

#   Establish a variable for unique zone names and loop through each one to create the zones in Azure DNS
$arrUniqueZoneNames = @()
$arrUniqueZoneNames = $arrImportedDNSRecords | Select-Object -Property zone_name | Sort-Object -Property zone_name | Get-Unique
foreach($zone in $arrUniqueZoneNames){
    $objError = @()
    $boolZoneExists = $null
    try {
        Get-AzDnsZone -Name $zone -ResourceGroupName $strDNS_ResourceGroupName -ErrorAction Stop
        $boolZoneExists = $true
    }
    catch {
        <#Do this if a terminating exception happens#>
    }

    
    
    try {
        New-AzDnsZone -Name $zone -ResourceGroupName $strDNS_ResourceGroupName -ErrorAction Stop
    }
    catch {
        $objError = $Error[0].Exception.Message

    }
    

}