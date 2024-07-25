<#
.SYNOPSIS
    Removes empty directories from a specified path.

.DESCRIPTION
    This function searches for and removes empty directories within a specified path. It can recursively check subdirectories to ensure all empty directories are removed.

.PARAMETER Path
    The path in which to search for empty directories. This parameter is mandatory.

.PARAMETER Recurse
    Indicates whether to recursively search for empty directories in subdirectories. The default value is $true. This parameter is optional.

.EXAMPLE
    Remove-EmptyDirectories -Path "C:\Temp"

    This command removes all empty directories within the "C:\Temp" directory.

.EXAMPLE
    Remove-EmptyDirectories -Path "C:\Temp" -Recurse $false

    This command removes empty directories within the "C:\Temp" directory, but does not search subdirectories.

.NOTES
    Use this function with caution, as it will permanently remove empty directories.
#>
Function Remove-EmptyDirectories {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidDefaultValueSwitchParameter", "", Scope = "Function", Target = "Recurse"
    )]
    param(
        [Parameter(Mandatory)][string] $Path,
        [switch] $Recurse = $true
    )

    # Ensure the specified path exists
    if (-Not (Test-Path -Path $Path)) {
        Write-Error "The specified path does not exist: $Path"
        return
    }

    # Get all directories, optionally including subdirectories
    $Directories = Get-ChildItem -Path $Path -Directory -Recurse:$Recurse

    # Iterate over directories and remove empty ones
    foreach ($Directory in $Directories) {
        if (-Not (Get-ChildItem -Path $Directory.FullName)) {
            Remove-Item -Path $Directory.FullName -Force -Recurse
            Write-Output "Removed empty directory: $($Directory.FullName)"
        }
    }
}