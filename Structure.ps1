
Function Copy-SPOListItems([String]$SourceURL, [String]$DestinationURL) {

    Write-host "Started Move-SpoList"     

    # looping through the lists
    $csvInput = Import-Csv -Path 'C:\Techcarrot\migration\Lists.csv'
    foreach ($row in $csvInput) {
        try {

            # Connects SharePoint Online
            # Connect-PnPOnline -Url $this.SourceUrl.Trim() -Interactive
            #  Get-PnPWeb

            $ListName = $row.ListName.Trim();
            Write-host "Executing "  $ListName

            $SourceListName = $ListName
            $DestinationListName = $ListName

            # $IsLookUpList = $row.IsLookUpList.Trim();
            Write-Host $ListName
            Write-Host $DestinationListName
            # Write-Host $IsLookUpList
            $FieldsToCopy = $row.Fields.Trim();
            Write-Host $FieldsToCopy


            #Connect to the Source site
            Connect-PnPOnline -Url $SourceSiteUrl -UseWebLogin
  
            #Get All Fields from the Source List
            $SourceListFields = Get-PnPField -List $SourceListName
 
            #Connect to Destination site
            Connect-PnPOnline -Url $DestinationSiteUrl -UseWebLogin
 
            #Get All Fields from the Desntination List
            $DestinationListFields = Get-PnPField -List $DestinationListName
 
            #Copy columns from the Source List to Destination List
            ForEach ($Field in $FieldsToCopy) {
                #Check if the destination list has the field already
                $DestinationFieldExist = ($DestinationListFields | Select -ExpandProperty InternalName).Contains($Field)
                If ($DestinationFieldExist -eq $false) {
                    #Get the field to copy
                    $SourceField = $SourceListFields | Where { $_.InternalName -eq $Field }
                    If ($SourceField -ne $Null) {
                        Add-PnPFieldFromXml -List $DestinationListName -FieldXml $SourceField.SchemaXml | Out-Null
                        Write-Host "Copied Field from Source to Destination List:"$Field -f Green
                    }
                    Else {
                        Write-Host "Field '$Field' does not Exist in the Source List!" -f Yellow
                    }
                }
                Else {
                    Write-host "Field '$Field' Already Exists in the Destination List!" -f Yellow
                }
            }


            #Read more: https://www.sharepointdiary.com/2021/05/sharepoint-online-copy-columns-from-one-list-to-another-using-powershell.html#ixzz7nhDxTrrh
        }
        catch {
            Write-Host -ForegroundColor Red 'Error ', ':', $Error[0].ToString();
            Start-Sleep 10
        }
    }
}


$SourceSiteUrl = "https://crescent.sharepoint.com/sites/Retail" 
$DestinationSiteUrl = "https://crescent.sharepoint.com/sites/Sales"
Copy-SPOListItems $SourceSiteURL $DestinationSiteURL