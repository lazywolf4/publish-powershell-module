#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'

Write-Host "Daten von Gitea..."
Write-Host "$env:INPUT_CHANGEDFILES"

$Modules = @($env:INPUT_MODULEPATH)

$Modules | ForEach-Object {
    Write-Host "Publishing '$_' to PowerShell Gallery"

    if ($env:INPUT_AUTOVERSION -eq "true") {
        $ModuleName = $_
        $ModulePath = $env:INPUT_MODULEFULLPATH
	& \data\autoversion.ps1
    }

    Register-PSRepository -Name "BagetNx" -SourceLocation "https://nuget.dev.nexcon-it.de/v3/index.json" -PublishLocation "https://nuget.dev.nexcon-it.de/api/v2/package" -InstallationPolicy "Trusted"
    Publish-Module -Path $_ -NuGetApiKey $env:INPUT_NUGETAPIKEY -Repository $env:INPUT_NUGETREPOSITORY
    Write-Host "'$_' published to PowerShell Gallery"
}
