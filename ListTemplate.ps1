#Custom Function to get all list templates from given site URL
Function Get-SPOCustomListTemplates([String]$SiteURL)
{
    #Get Credentials to connect
    $Cred= Get-Credential
    $Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.Username, $Cred.Password)
   
    #Setup the context
    $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
    $Ctx.Credentials = $Credentials
 
    #Get Custom list templates
    $ListTemplates=$Ctx.site.GetCustomListTemplates($Ctx.site.RootWeb)
    $Ctx.Load($ListTemplates)
    $Ctx.ExecuteQuery()
 
    #Get Custom list templates
    $ListTemplates | Select Name, baseType, ListTemplateTypeKind | Format-Table -AutoSize
}
 
#Variable
$SiteURL="https://techcarrotae.sharepoint.com/sites/MigrationTestsite"
 
#Call the function to get all list templates
Get-SPOCustomListTemplates $SiteURL


#Read more: https://www.sharepointdiary.com/2017/08/sharepoint-online-get-list-templates-using-powershell.html#ixzz7m7Y4TUjE