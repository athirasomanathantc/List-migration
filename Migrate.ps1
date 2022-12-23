Function Copy-SPOAttachments() {
    param
    (
        [Parameter(Mandatory = $true)] [Microsoft.SharePoint.Client.ListItem] $SourceItem,
        [Parameter(Mandatory = $true)] [Microsoft.SharePoint.Client.ListItem] $DestinationItem
    )
    Try {
        #Get All Attachments from Source list items
        $Attachments = Get-PnPProperty -ClientObject $SourceItem -Property "AttachmentFiles" -Connection $SourceConn
        $Attachments | ForEach-Object {
            #Download the Attachment to Temp
            $File = Get-PnPFile -Connection $SourceConn -Url $_.ServerRelativeUrl -FileName $_.FileName -Path $Env:TEMP -AsFile -Force
            #Add Attachment to Destination List Item
            $FileStream = New-Object IO.FileStream(($Env:TEMP + "\" + $_.FileName), [System.IO.FileMode]::Open) 
            $AttachmentInfo = New-Object -TypeName Microsoft.SharePoint.Client.AttachmentCreationInformation
            $AttachmentInfo.FileName = $_.FileName
            $AttachmentInfo.ContentStream = $FileStream
            $AttachFile = $DestinationItem.AttachmentFiles.Add($AttachmentInfo)
            Invoke-PnPQuery -Connection $DestinationConn
       
            #Delete the Temporary File
            Remove-Item -Path $Env:TEMP\$($_.FileName) -Force
        }
    }
    Catch {
        write-host -f Red "Error Copying Attachments:" $_.Exception.Message
    }
}
Function Copy-SPOListItems() {
    param
    (
        [Parameter(Mandatory = $true)] [Microsoft.SharePoint.Client.List] $SourceList,
        [Parameter(Mandatory = $true)] [Microsoft.SharePoint.Client.List] $DestinationList
    )
    Try {
        #Get All Items from the Source List in batches
        Write-Progress -Activity "Reading Source..." -Status "Getting Items from Source List. Please wait..."
        $SourceListItems = Get-PnPListItem -List $SourceList -PageSize 500 -Connection $SourceConn
        $SourceListItemsCount = $SourceListItems.count
        Write-host "Total Number of Items Found:"$SourceListItemsCount     
   
        #Get fields to Update from the Source List - Skip Read only, hidden fields, content type and attachments
        $SourceListFields = Get-PnPField -List $SourceList -Connection $SourceConn | Where { (-Not ($_.ReadOnlyField)) -and (-Not ($_.Hidden)) -and ($_.InternalName -ne "ContentType") -and ($_.InternalName -ne "Attachments") }
 
        #Loop through each item in the source and Get column values, add them to Destination
        [int]$Counter = 1
        ForEach ($SourceItem in $SourceListItems) { 
            $ItemValue = @{}
            #Map each field from source list to Destination list
            Foreach ($SourceField in $SourceListFields) {
                #Check if the Field value is not Null
                If ($SourceItem[$SourceField.InternalName] -ne $Null) {
                    #Handle Special Fields
                    $FieldType = $SourceField.TypeAsString                   
   
                    If ($FieldType -eq "User" -or $FieldType -eq "UserMulti") {
                        #People Picker Field
                        $PeoplePickerValues = $SourceItem[$SourceField.InternalName] | ForEach-Object { $_.Email }
                        $ItemValue.add($SourceField.InternalName, $PeoplePickerValues)
                    }
                    ElseIf ($FieldType -eq "Lookup" -or $FieldType -eq "LookupMulti") {
                        # Lookup Field
                        $LookupIDs = $SourceItem[$SourceField.InternalName] | ForEach-Object { $_.LookupID.ToString() }
                        $ItemValue.add($SourceField.InternalName, $LookupIDs)
                    }
                    ElseIf ($FieldType -eq "URL") {
                        #Hyperlink
                        $URL = $SourceItem[$SourceField.InternalName].URL
                        $URL = $URL -replace "AGIIntranetUAT" , "AGIIntranetProd"
                        Write $URL
                        $Description = $SourceItem[$SourceField.InternalName].Description
                        $Description = $Description -replace "AGIIntranetUAT" , "AGIIntranetProd"
                        Write $Description
                        $ItemValue.add($SourceField.InternalName, "$URL, $Description")
                    }
                    ElseIf ($FieldType -eq "TaxonomyFieldType" -or $FieldType -eq "TaxonomyFieldTypeMulti") {
                        #MMS
                        $TermGUIDs = $SourceItem[$SourceField.InternalName] | ForEach-Object { $_.TermGuid.ToString() }                   
                        $ItemValue.add($SourceField.InternalName, $TermGUIDs)
                    }
                    Else {
                        #Get Source Field Value and add to Hashtable                       
                        $ItemValue.add($SourceField.InternalName, $SourceItem[$SourceField.InternalName])
                    }
                }
            }
            #Copy Created by, Modified by, Created, Modified Metadata values
            #$ItemValue.add("Created", $SourceItem["Created"]);
            #$ItemValue.add("Modified", $SourceItem["Modified"]);
            #$ItemValue.add("Author", $SourceItem["Author"].Email);
            #$ItemValue.add("Editor", $SourceItem["Editor"].Email);
 
            Write-Progress -Activity "Copying List Items:" -Status "Copying Item ID '$($SourceItem.Id)' from Source List ($($Counter) of $($SourceListItemsCount))" -PercentComplete (($Counter / $SourceListItemsCount) * 100)
             
            #Copy column value from Source to Destination
            $NewItem = Add-PnPListItem -List $DestinationList -Values $ItemValue -Connection $DestinationConn
   
                




            #Copy Attachments
            Copy-SPOAttachments -SourceItem $SourceItem -DestinationItem $NewItem
   
            Write-Host "Copied Item ID from Source to Destination List:$($SourceItem.Id) ($($Counter) of $($SourceListItemsCount))"
            $Counter++            
        }
    }
    Catch {
        Write-host -f Red "Error:" $_.Exception.Message
    }
}
Function Move-SpoList([String]$SourceURL, [String]$DestinationURL) {

    #param
    # (
    #    [Parameter(Mandatory = $true)] [Microsoft.SharePoint.Client.List] $SourceURL,
    #   [Parameter(Mandatory = $true)] [Microsoft.SharePoint.Client.List] $DestinationURL
    # )

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

            #Getting List Template Name
            # $timestamp = Get-Date -Format FileDateTimeUniversal
            # $tempFile = './SourceListBackup/' + $ListName + $timestamp + '.xml';

            # Get-PnPSiteTemplate -Handlers Lists -ListsToExtract $ListName -Out $tempFile

            #Adding Rows to List Template
            # if ($IsLookUpList -eq 1) {
            #     Add-PnPDataRowsToSiteTemplate -Path $tempFile -List $ListName -Query '<View></View>'
            #}

            #Applying Template to Destination Site
            ##Get-PnPWeb
            # Invoke-PnPSiteTemplate -Path $tempFile

            #Connect to Source and destination sites
            #$SourceSiteURL = "https://techcarrotae.sharepoint.com/sites/MigrationTestsite"

            #$DestinationSiteURL = "https://techcarrotae.sharepoint.com/sites/MigrationTestsite"
            $SourceConn = Connect-PnPOnline -Url $SourceURL -UseWebLogin -ReturnConnection

            $DestinationConn = Connect-PnPOnline -Url $DestinationURL -UseWebLogin -ReturnConnection
            $SourceList = Get-PnPList -Identity $SourceListName -Connection $SourceConn
  
            
            $DestinationList = Get-PnPList -Identity $DestinationListName -Connection $DestinationConn

           
            #Read more: https://www.sharepointdiary.com/2021/05/sharepoint-online-copy-columns-from-one-list-to-another-using-powershell.html#ixzz7ndSSJ2gQ

            Copy-SPOListItems -SourceList $SourceList -DestinationList $DestinationList

        }
        catch {
            Write-Host -ForegroundColor Red 'Error ', ':', $Error[0].ToString();
            Start-Sleep 10
        }
    }
}



#Set Parameters
$SourceSiteURL = "https://aginvestment.sharepoint.com/sites/AGIIntranetUAT"
#$SourceListName = "Business"
  
$DestinationSiteURL = "https://aginvestment.sharepoint.com/sites/AGIIntranetProd"
#$DestinationListName = "Business1"
  
#Connect to Source and destination sites
#$SourceConn = Connect-PnPOnline -Url $SourceSiteURL -UseWebLogin -ReturnConnection
#$SourceList = Get-PnPList -Identity $SourceListName -Connection $SourceConn
  
#$DestinationConn = Connect-PnPOnline -Url $DestinationSiteURL -UseWebLogin -ReturnConnection
#$DestinationList = Get-PnPList -Identity $DestinationListName -Connection $DestinationConn

Move-SpoList $SourceSiteURL $DestinationSiteURL
