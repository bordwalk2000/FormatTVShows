#Requires -Module ModuleBuilder
param(
    [version]$Version = (Import-PowerShellDataFile "$PSScriptRoot\Source\MediaFileManager.psd1").ModuleVersion
)

$params = @{
    SourcePath = "$PSScriptRoot\Source\MediaFileManager.psd1"
    CopyPaths  = @("$PSScriptRoot\README.md")
    Version    = $Version
}
Build-Module @params