Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
#Parameters
$SiteURL="https://intranet.crescent.com"
$ListName="Projects"
$NewListName = "Projects Archive"
$SaveData= $False
 
Try {
    #Get the web and List
    $Web = Get-SPWeb $SiteURL
    $List = $Web.Lists[$ListName]
 
    #Check if the new list doesn't exists
    If($Web.Lists.TryGetList($NewListName) -eq $null)
    {
        #Save list as template
        $List.SaveAsTemplate($List.ID.ToString(), $List.ID.ToString(), [string]::Empty, $SaveData)
 
        #Get the List template
        $ListTemplate = $web.Site.GetCustomListTemplates($web)[$List.ID.ToString()]
 
        #Clone list
        $NewList = $web.Lists.Add($NewListName, "$($NewListName)-$($List.Description)", $ListTemplate)
 
        #Remove the List template file Created
        $ListTemplateFile = $web.Site.RootWeb.GetFolder("_catalogs/lt").Files | where {$_.Name -eq $ListTemplate.InternalName}
        $ListTemplateFile.Delete()
 
        write-host -f Green "List '$ListName' Cloned to '$NewListName!'"
    }
    Else
    {
        write-host -f Yellow "List '$NewListName' already exists!"
    }
 
}
Catch {
    write-host -f Red "Error Adding Template to Document Library!" $_.Exception.Message


#Read more: https://www.sharepointdiary.com/2018/02/copy-sharepoint-list-using-powershell.html#ixzz7m7a3DZek