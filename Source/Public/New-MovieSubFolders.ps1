<#
.SYNOPSIS
Creates a new movie folder structure with predefined subfolders.

.DESCRIPTION
This function creates a new parent movie folder and a set of predefined subfolders for special features such as 'Behind The Scenes', 'Deleted Scenes', 'Featurettes', and others. The parent folder is created at the specified location.

.PARAMETER MovieFolderName
The name of the movie folder to be created.

.PARAMETER SaveLocation
The path where the movie folder and its subfolders will be created. This is a mandatory parameter.

.EXAMPLE
New-MovieSubFolders -MovieFolderName "NewMovie" -SaveLocation "C:\Movies"

Creates a new folder named "NewMovie" in the "C:\Movies" directory with the predefined subfolders.

.EXAMPLE
New-MovieSubFolders .

Creates the predefined subfolders in the current directory.

.NOTES
Author: Bradley Herbst
Created: Oct 13, 2021
#>
Function New-MovieSubFolders {
    param (
        [Parameter()]
        [string]
        $MovieFolderName,

        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Path to create the empty movie folders."
        )]
        [Alias("PSPath")]
        [ValidateScript(
            {
                Test-Path -Path $_
            }
        )]
        [IO.DirectoryInfo]
        $SaveLocation
    )

    # Define params for New-Item for movie folder name directory.
    $params = @{
        ItemType    = "Directory"
        Name        = $MovieFolderName
        Path        = $SaveLocation
        ErrorAction = "SilentlyContinue"
    }

    # Remove empty items from params
    foreach ($Key in @($params.Keys)) {
        if (-not $params[$Key]) {
            $params.Remove($Key)
        }
    }

    #Create Parent Folder
    New-Item @params

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

        # Remove empty items from params
        foreach ($Key in @($Params.Keys)) {
            if (-not $Params[$Key]) {
                $Params.Remove($Key)
            }
        }

        # Check if $SaveLocation is defined and if so add it.
        if ($SaveLocation) {
            $params.Path = (Join-Path $SaveLocation $MovieFolderName)
        }

        # Create subfolders
        New-Item @params
    }
}