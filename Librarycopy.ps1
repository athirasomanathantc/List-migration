#Parameters
$SourceSiteURL = "https://athiras.sharepoint.com/sites/marketing"
$DestinationSiteURL = "https://athiras.sharepoint.com/sites/Techcarrot"
  
#Connect to the source Site
Connect-PnPOnline -URL $SourceSiteURL -UseWebLogin
  
#Get all document libraries
$SourceLibraries =  Get-PnPList -Includes RootFolder | Where {$_.BaseType -eq "DocumentLibrary" -and $_.Hidden -eq $False}
  
#Connect to the destination site
Connect-PnPOnline -URL $DestinationSiteURL -UseWebLogin
  
#Connect to the source Site
Connect-PnPOnline -URL $SourceSiteURL -UseWebLogin
  
#Get all document libraries
$SourceLibraries =  Get-PnPList -Includes RootFolder | Where {$_.BaseType -eq "DocumentLibrary" -and $_.Hidden -eq $False}
  
#Connect to the destination site
Connect-PnPOnline -URL $DestinationSiteURL -UseWebLogin
  
#Get All Lists in the Destination site
$DestinationLibraries = Get-PnPList
  
ForEach($SourceLibrary in $SourceLibraries)
{
    #Check if the library already exists in target
    If(!($DestinationLibraries.Title -contains $SourceLibrary.Title))
    {
        #Create a document library
        $NewLibrary  = New-PnPList -Title $SourceLibrary.Title -Template DocumentLibrary
        Write-host "Document Library '$($SourceLibrary.Title)' created successfully!" -f Green
    }
    else
    {
        Write-host "Document Library '$($SourceLibrary.Title)' already exists!" -f Yellow
    }
  
    #Get the Destination Library
    $DestinationLibrary = Get-PnPList $SourceLibrary.Title -Includes RootFolder
    $SourceLibraryURL = $SourceLibrary.RootFolder.ServerRelativeUrl
    $DestinationLibraryURL = $DestinationLibrary.RootFolder.ServerRelativeUrl
  
    #Copy All Content from Source Library to Destination library
    Copy-PnPFile -SourceUrl $SourceLibraryURL -TargetUrl $DestinationLibraryURL  -Overwrite
    Write-host "`tContent Copied from $SourceLibraryURL to  $DestinationLibraryURL Successfully!" -f Green
}