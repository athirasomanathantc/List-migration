#Load SharePoint CSOM Assemblies
Add-Type -Path "C:\Program Files\SharePoint Online Management Shell\Microsoft.Online.SharePoint.PowerShell\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\SharePoint Online Management Shell\Microsoft.Online.SharePoint.PowerShell\Microsoft.SharePoint.Client.Runtime.dll"
  
#Variables for Processing
$SiteURL = "https://techcarrotae.sharepoint.com/sites/MigrationTestsite"
$ListName = "Projects"
 
#Get Credentials to connect
$Cred = Get-Credential
 
#Setup the context
$Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
$Ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.UserName, $Cred.Password)
     
#Create a custom list in sharepoint online using powershell
$ListCreationInfo = New-Object Microsoft.SharePoint.Client.ListCreationInformation
$ListCreationInfo.Title = $ListName
$ListCreationInfo.TemplateType = 100
$List = $Ctx.Web.Lists.Add($ListCreationInfo)
$List.Description = "Projects List"
$List.Update()
$Ctx.ExecuteQuery()


#Read more: https://www.sharepointdiary.com/2014/12/sharepoint-online-powershell-to-create-list.html#ixzz7m6P10294