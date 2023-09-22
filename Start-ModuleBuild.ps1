param(
    [version]$Version = "3.0.0"
)
#Requires -Module ModuleBuilder

$params = @{
    SourcePath = "$PSScriptRoot\Source\Format-TVShows.psd1"
    # CopyPaths = @("$PSScriptRoot\README.md")
    Version = $Version
    UnversionedOutputDirectory = $true
}
Build-Module @params