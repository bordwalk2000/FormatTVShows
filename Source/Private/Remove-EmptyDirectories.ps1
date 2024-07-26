<#
.SYNOPSIS
    Removes empty directories from the specified path.

.DESCRIPTION
    The `Remove-EmptyDirectories` function removes directories that do not contain any files. It recursively traverses the specified path to identify and remove empty directories.

.PARAMETER Path
    The path from which empty directories will be removed. This parameter is mandatory and must be a valid path.

.NOTES
    Use this function with caution, as it will permanently remove empty directories and all empty subdirectories.
#>
Function Remove-EmptyDirectories {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidDefaultValueSwitchParameter", "", Scope = "Function", Target = "Recurse"
    )]
    param(
        [Parameter(
            Mandatory
        )]
        [ValidateScript(
            {
                Test-Path -Path $_
            }
        )]
        [string]
        $Path
    )

    Get-ChildItem -Path $Path -Recurse
    | Where-Object {
        $_.PSIsContainer -and @(
            Get-ChildItem -LiteralPath $_.FullName -Recurse
            | Where-Object { -not($_.PSIsContainer) }
        ).Length -eq 0
    }
    | Remove-Item -Recurse
}