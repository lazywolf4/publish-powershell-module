#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'

$Modules = $null
if ([string]::IsNullOrWhiteSpace($env:INPUT_MODULEPATH)) {
    $Modules = Get-ChildItem -Recurse -Filter '*.psd1' |
        Select-Object -Unique -ExpandProperty Directory
} else {
    $Modules = @($env:INPUT_MODULEPATH)
}

$Modules | ForEach-Object {
    Write-Host "Publishing '$_' to PowerShell Gallery"

    if ($env:INPUT_AUTOVERSION -eq "true") {
        $ModuleName = $_
        $ModulePath = $env:INPUT_MODULEFULLPATH
	    ./autoversion.ps1
    }

    Register-PSRepository -Name "BagetNx" -SourceLocation "https://nuget.dev.nexcon-it.de/v3/index.json" -PublishLocation "https://nuget.dev.nexcon-it.de/api/v2/package" -InstallationPolicy "Trusted"
    Publish-Module -Path $_ -NuGetApiKey $env:INPUT_NUGETAPIKEY -Repository $env:INPUT_NUGETREPOSITORY
    Write-Host "'$_' published to PowerShell Gallery"
}
