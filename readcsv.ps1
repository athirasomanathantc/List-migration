class CopySpoList {
    [string]$SourceUrl;
    [string]$DestinationUrl;
    [string]$DestinationEnvironment;
    [string]$SourceEnvironment;
    [Object]$Environments;
    [bool]$IsEnvironmentValid = $true;

    CopySpoList() {
        Write-Host 'Below is the list of valid environments' -ForegroundColor Green;
        Write-Host ('DEV', 'QA', 'PROD') -Separator ', -> ' -ForegroundColor DarkGreen;
        $this.Environments = Get-Content -Path '..\environments.json' | ConvertFrom-Json;
        $this.SourceEnvironment = Read-Host 'Enter the source environment';
        $this.ValidateEnvironment($this.SourceEnvironment.ToUpper(), 'Source')
        $this.DestinationEnvironment = Read-Host 'Enter the destination environment';
        $this.ValidateEnvironment($this.DestinationEnvironment.ToUpper(), 'Destination')
    }

    [void]  ValidateEnvironment([string]$environmentName, [string]$environmentType) {
        switch ($environmentName) {
            'DEV' {
                if ($environmentType -eq 'Source') {
                    $this.SourceUrl = $this.Environments.DEV;
                } else {
                    $this.DestinationUrl = $this.Environments.DEV;
                }
                break;
            }
            'QA' {
                if ($environmentType -eq 'Source') {
                    $this.SourceUrl = $this.Environments.QA;
                } else {
                    $this.DestinationUrl = $this.Environments.QA;
                }
                break;
            }
            'PROD' {
                if ($environmentType -eq 'Source') {
                    $this.SourceUrl = $this.Environments.PROD;
                } else {
                    $this.DestinationUrl = $this.Environments.PROD;
                }
                break;
            }
            Default {
                $this.IsEnvironmentValid = $false;
                Write-Host 'Value does not fall in valid environment range' -ForegroundColor Red;
                Write-Host ('DEV', 'QA', 'PROD') -Separator ', -> ' -ForegroundColor Red
            }
        }
    }

    [void] MoveSpoList() {
        # looping through the lists
        $csvInput = Import-Csv -Path '.\Lists.csv'
        foreach ($row in $csvInput) {
            try {

                # Connects SharePoint Online
                Connect-PnPOnline -Url $this.SourceUrl.Trim() -Interactive
                Get-PnPWeb

                $ListName = $row.ListName.Trim();
                $IsLookUpList = $row.IsLookUpList.Trim();
                Write-Host $ListName
                Write-Host $IsLookUpList

                #Getting List Template Name
                $timestamp = Get-Date -Format FileDateTimeUniversal
                $tempFile = './SourceListBackup/' + $ListName + $timestamp + '.xml';

                Get-PnPSiteTemplate -Handlers Lists -ListsToExtract $ListName -Out $tempFile

                #Adding Rows to List Template
                if ($IsLookUpList -eq 1) {
                    Add-PnPDataRowsToSiteTemplate -Path $tempFile -List $ListName -Query '<View></View>'
                }

                #Applying Template to Destination Site
                Connect-PnPOnline -Url $this.DestinationUrl.Trim() -Interactive
                Get-PnPWeb
                Invoke-PnPSiteTemplate -Path $tempFile
            } catch {
                Write-Host -ForegroundColor Red 'Error ', ':', $Error[0].ToString();
                Start-Sleep 10
            }
        }
    }
}

[CopySpoList]$copySpList = [CopySpoList]::new();
if ($copySpList.IsEnvironmentValid) {
    $copySpList.MoveSpoList();
}