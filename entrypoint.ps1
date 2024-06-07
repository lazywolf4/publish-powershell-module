#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'

$changedFilesString = "$env:INPUT_CHANGEDFILES"
$changedFilesIgnoreString = "$env:INPUT_CHANGEDFILESIGNOREDEXTENSIONS"

#changedFilesIgnore string to array
$changedFilesIgnoreArray = $changedFilesIgnoreString.Split(',') 

#==Array erstellung aus JSON==
# Extrahiere Werte zwischen den Anführungszeichen
$changedFilesValues = $changedFilesString -split '\",\"' | ForEach-Object { $_ -replace '[\[\]"]', '' }
# Erstelle ein Array aus den extrahierten Werten
$changedFilesArray = @($changedFilesValues)

#Init empty array for paths that should be processed, after scanning for invalid file extensions
$modulePathArray = @()

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

Write-Host "Pfade zum verarbeiten:"
$modulePathArray
