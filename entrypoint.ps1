#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'
$VerbosePreference = "Continue"

$changedFilesString = "$env:INPUT_CHANGEDFILES"
$changedFilesIgnoreString = "$env:INPUT_CHANGEDFILESIGNOREDEXTENSIONS"

if (-Not ($changedFilesString -eq "[]")) {
    #changedFilesIgnore string to array
    $changedFilesIgnoreArray = $changedFilesIgnoreString.Split(',') 
    
    #==Array erstellung aus JSON==
    # Extrahiere Werte zwischen den Anführungszeichen
    $changedFilesValues = $changedFilesString -split '\",\"' | ForEach-Object { $_ -replace '[\[\]"]', '' }
    # Erstelle ein Array aus den extrahierten Werten
    $changedFilesArray = @($changedFilesValues)
    
    #Init empty array for paths that should be processed, after scanning for invalid file extensions
    $modulePathArray = @()
    
    if ($changedFilesArray.Count -eq 0) {
        exit 0
    }
    
    foreach ($changedFile in $changedFilesArray) {
        #Extract Filename and extension
        $filename = Split-Path -Path $changedFile -Leaf
        $extension = $filename.Split(".")[1];
    
    
        #Init var skipFile (this inidcates if the current path should be added to "process array")
        [bool]$skipFile = $false
        #Check if filetype is not on blacklist
        foreach ($ignoreFiletype in $changedFilesIgnoreArray) {
            if ($ignoreFiletype -eq $extension) {
                [bool]$skipFile = $true
                Break
            }
        }
    
        if (-Not ($skipFile)) {
            #Get module paths like this "Modules/Xyz", without Filename etc.
            $modulePathArray += $changedFile.Split("/")[0..1] -join "/"
        }
    }
    
    
    #Dedup array
    $modulePathArray = $modulePathArray | select -Unique
}

Write-Host "add repo"
#Init custom ps gallery (if needed)
if (-not ($env:INPUT_NUGETREPOSITORYSOURCEURL -eq $null)) {
    Register-PSRepository -Name "$env:INPUT_NUGETREPOSITORY" -SourceLocation "$env:INPUT_NUGETREPOSITORYSOURCEURL" -PublishLocation "$env:INPUT_NUGETREPOSITORYPUBLISHURL" -InstallationPolicy "Trusted"
}
Write-Host "added repo"

foreach ($currentModulePath in $modulePathArray) {
    $ModuleName = $currentModulePath.Split("/")[1]
    Write-Host "Publishing $ModuleName to $env:INPUT_NUGETREPOSITORY"

    $ModulePath = $currentModulePath

    if ($env:INPUT_AUTOVERSION -eq "true") {
        & \data\autoversion.ps1
    }

    Publish-Module -Path $ModulePath -NuGetApiKey $env:INPUT_NUGETAPIKEY -Repository $env:INPUT_NUGETREPOSITORY
    Write-Host "$ModuleName successful published to $env:INPUT_NUGETREPOSITORY"
}