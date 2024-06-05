$ManifestPath = "$ModulePath\$ModuleName.psd1"
$FingerprintPath = "$ModulePath\.version_fingerprint.tmp"

#Dependencys
#Step-ModuleVersion is from https://github.com/RamblingCookieMonster/BuildHelpers
#Module must be imported!
if (-not(Get-Module -ListAvailable -Name BuildHelpers)) {
    Install-Module BuildHelpers
    Import-Module BuildHelpers
}

#Create Module fingerprint
#https://powershellexplained.com/2017-10-14-Powershell-module-semantic-version/

#Generate new fingerprint
Import-Module "$ModulePath"
$commandList = Get-Command -Module $ModuleName
Remove-Module $ModuleName

Write-Host 'Calculating fingerprint'
$fingerprint = foreach ( $command in $commandList )
{
    foreach ( $parameter in $command.parameters.keys )
    {
        '{0}:{1}' -f $command.name, $command.parameters[$parameter].Name
        $command.parameters[$parameter].aliases | 
            Foreach-Object { '{0}:{1}' -f $command.name, $_}
    }
}


#Get old fingerprint (from file)
if ( Test-Path "$FingerprintPath" ) {
    $oldFingerprint = Get-Content "$FingerprintPath"
}

#Compare old with new fingerprint
#Default type is patch
$bumpVersionType = 'Patch'
#Detecting new features
$fingerprint | Where {$_ -notin $oldFingerprint } | 
    ForEach-Object {$bumpVersionType = 'Minor'; "  $_"}
#Detecting breaking changes
$oldFingerprint | Where {$_ -notin $fingerprint } | 
    ForEach-Object {$bumpVersionType = 'Major'; "  $_"}

#Store new fingerprint as old fingerprint
Set-Content -Path "$FingerprintPath" -Value $fingerprint

#Update version in manifest
Write-Host "bumpVersionType: $bumpVersionType"
Step-ModuleVersion -Path "$ManifestPath" -By $bumpVersionType
