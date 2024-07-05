<#
.SYNOPSIS
Creates a new movie folder structure with predefined subfolders.

.DESCRIPTION
This function creates a new parent movie folder and a set of predefined subfolders for special features such as 'Behind The Scenes', 'Deleted Scenes', 'Featurettes', and others. The parent folder is created at the specified location.

.PARAMETER MovieFolderName
The name of the movie folder to be created. This is a mandatory parameter.

.PARAMETER SaveLocation
The path where the movie folder and its subfolders will be created. This parameter is optional. If not specified, the folders are created in the current directory.

.EXAMPLE
New-MovieFolderStructure -MovieFolderName "NewMovie"
Creates a new folder named "NewMovie" in the current directory with the predefined subfolders.

.EXAMPLE
New-MovieFolderStructure -MovieFolderName "NewMovie" -SaveLocation "C:\Movies"
Creates a new folder named "NewMovie" in the "C:\Movies" directory with the predefined subfolders.

.NOTES
Author: Bradley Herbst
Created: Oct 13, 2021
#>
Function New-MovieFolderStructure {
    param (
        [Parameter(
            Mandatory,
            Position = 0
        )]
        [string]
        $MovieFolderName,

        [Parameter(
            Position = 1,
            HelpMessage = "Path to create the empty movie folders."
        )]
        [ValidateScript(
            {
                Test-Path -Path $_
            }
        )]
        [IO.DirectoryInfo] $SaveLocation
    )

    #Create Parent Folder
    New-Item -ItemType Directory $MovieFolderName -ErrorAction SilentlyContinue

    #Define Special Features Folders
    $Folders = 'Behind The Scenes',
    'Deleted Scenes',
    'Featurettes',
    'Interviews',
    'Scenes',
    'Shorts',
    'Trailers',
    'Other'

    #Create Special Features Folders
    foreach ($Folder in $Folders) {
        $params = @{
            ItemType    = "Directory"
            Path        = $MovieFolderName
            Name        = $Folder
            ErrorAction = "SilentlyContinue"
        }

        # Check if $SaveLocation is defined and if so add it.
        if ($SaveLocation) {
            $params.Path = (Join-Path $SaveLocation $MovieFolderName)
        }

        # Create subfolders
        New-Item @params
    }
}