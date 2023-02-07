###################### Variables Requiring Input #################
$strExportDirPath = "(File Directory Path to Store CSVs After Completion)"
###################### Variables Requiring Input #################
$arrAllGroups = @()
$arrAllGroups = Get-MgGroup -All $true
$arrGroup = @()
$intProgressStatus = 1
$psobjGroupsDatabase = @()
foreach($arrGroup in $arrAllGroups){
    $objError = ""
    $arrGetMgGroup = @()
    Write-Progress `
    -Activity "Building Group Database" `
    -Status "$($intProgressStatus) of $($arrAllGroups.Count)" `
    -CurrentOperation $intProgressStatus `
    -PercentComplete  (($intProgressStatus / @($arrAllGroups).Count) * 100)
    #  Try/Catch - Resolve Groups
    try {
        $arrGetMgGroup = Get-MgGroup -GroupId $arrGroup.Id -ErrorAction Stop
        $strPriority = ""
        $objPhoto = ""
        $strGroupType = ""
        $arrOwner = @()
        $arrAcceptedSenders = @()
        $arrMembers = @()
        $arrMemberOf = @()
        $arrPermissionGrants = @()
        




        #build a routine to calculate the priority rank of a group later
        $strPriority = "Low"
    }
    catch {
        $objError += Get-Error
    }
    $psobjGroupsDatabase += [PSCustomObject]@{
        Id = $arrGetMgUser.Id
        Photo = $objPhoto
        Priority = $strPriority
        DisplayName = $arrGetMgGroup.DisplayName
        Description = $arrGetMgGroup.Description
        GroupType = $strGroupType
        Owner = $arrOwner
        AcceptedSender = $arrAcceptedSenders
        Members = $arrMembers
        MemberOf = $arrMemberOf
        PermissionGrants = $arrPermissionGrants
        Error = $objError
    }   
    $intProgressStatus++
}