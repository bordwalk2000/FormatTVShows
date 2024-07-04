<#
.SYNOPSIS
Recreates a folder and file structure to allow testing of the against a copy so 
that if the Format-TVShow function doesn't work as as expected, the actual files
are unchanged.

.DESCRIPTION
Will recreate a folder structure including all subfolder and files creating 0kb files 

The test folder will the be saved in the root of the user profile directory
unless a different destination folder location was specified.

.PARAMETER TVShowFolder
Specify the path to the folder that you want to create a test copy of.

.PARAMETER DestinationFolder
Specify the location to where you want the Test TV Show folder structure to be
saved.  By Default it goes to the root of the user profile directory.  This is
because since the Format-TVSHow function uses the folder name to do the search,
it needs to be saved in a different location since I don't want to have the
name of the top level folder changed in anyways.

#>
Function Copy-FolderStructure {
    param(
        [Parameter(Mandatory)][IO.DirectoryInfo] $TVShowFolder,
        [IO.DirectoryInfo] $DestinationFolder = [Environment]::GetFolderPath('UserProfile')
    )
    
    $Path = (New-Item -ItemType Directory -Path $DestinationFolder -Name $(
            Split-Path $TVShowFolder -Leaf) -ErrorAction Stop
    ).FullName
    Get-ChildItem -Path $TVShowFolder -Recurse
    | ForEach-Object {
        if ($_.Gettype().Name -eq 'DirectoryInfo') {
            New-Item -ItemType Directory -Path $(
                Join-Path -Path $Path -ChildPath (
                    Split-Path $_.FullName
                ).Replace($TVShowFolder,'')
            ) -Name $_.BaseName
        }
        else {
            New-Item -Path $([WildcardPattern]::Escape($(
                Join-Path -Path $Path -ChildPath (Split-Path $_.FullName).Replace($TVShowFolder,'')
            ))) -Name $_.Name
        }
    }
}