<#
.SYNOPSIS
Creates new movie folders in specified watch directories based on movie data from TheMovieDB.

.DESCRIPTION
This function scans specified watch directories for newly created folders within a defined period and uses TheMovieDB API to create properly formatted movie folder names. It then creates these movie folders in the specified output directory, including necessary subfolders.

.PARAMETER WatchDirectory
The directories where new movie folders will be created. This parameter is mandatory and must be a valid path.

.PARAMETER OutputDirectory
Path to the location of transcoded movie folders ready to be moved. This parameter is mandatory and must be a valid directory.

.PARAMETER LastCreatedDaysAgo
Skip folders that have LastWriteTime less than this many days ago. The default value is 7 days.

.PARAMETER TheMovieDB_API
The API key used to authenticate with TheMovieDB API. This parameter is mandatory.

.EXAMPLE
New-MovieFolder -WatchDirectory "C:\Movies\Watch" -OutputDirectory "D:\Movies" -TheMovieDB_API "your_api_key"

This command scans the "C:\Movies\Watch" directory for newly created folders, uses TheMovieDB API to format movie folder names, and creates these folders in the "D:\Movies" directory.

.INPUTS
[String[]] $WatchDirectory
[IO.DirectoryInfo] $OutputDirectory
[int] $LastCreatedDaysAgo
[string] $TheMovieDB_API

.OUTPUTS
System.Void
This function does not return any output.

.NOTES
Author: Bradley Herbst
Created: July 26, 2024

The function uses Get-MovieFolderName and New-MovieSubFolders to create and organize movie folders.
Ensure that the API key is valid and has the necessary permissions.
#>

Function New-MovieFolder {
    param(
        [Parameter(
            Mandatory,
            HelpMessage = "The directories where new movie folders will be created."
        )]
        [ValidateScript(
            {
                Test-Path -Path $_
            }
        )]
        [String[]]
        $WatchDirectory,

        [Parameter(
            Mandatory,
            HelpMessage = "Path to the location of transcoded movie folders ready to be moved."
        )]
        [ValidateScript(
            {
                Test-Path -Path $_
            }
        )]
        [IO.DirectoryInfo]
        $OutputDirectory,

        [Parameter(
            HelpMessage = "Skip folders that have LastWriteTime less than this many hours ago."
        )]
        [int]
        $LastCreatedDaysAgo = 7,

        [Parameter(
            Mandatory
        )]
        [string]
        $TheMovieDB_API
    )

    # Get List of Folders in the $WatchDirectory folders that were created less than $LastCreatedDaysAgo.
    $MovieFolderList = Get-ChildItem -Path $WatchDirectory -Directory
    | Where-Object CreationTime -gt (Get-Date).AddDays(-$LastCreatedDaysAgo)

    foreach ($Movie in $MovieFolderList) {
        # Define parameters for Get-MovieFolderName function
        $params = @{
            MovieSearchString = $Movie.Name.Trim()
            TheMovieDB_API    = $TheMovieDB_API
        }

        # Verify Get-MovieFolderName returns results.
        if ( -not(Get-MovieFolderName @params -OutVariable MovieFolderName) ) {
            Write-Error "Unable to create movie folder for $($Movie.Name.Trim())."
            continue
        }

        $params = @{
            Path        = $OutputDirectory
            ChildPath   = "$MovieFolderName"
            Resolve     = $true
            OutVariable = 'NewMovieFolderPath'
            ErrorAction = 'SilentlyContinue'
        }

        # Define path where folder is going to be created & check if it exists.
        if (Join-Path @params) {
            # Create movie subfolder directories in already created directory.
            New-MovieSubFolders -SaveLocation "$NewMovieFolderPath" | Out-Null
        }
        else {
            # Define params for creating new movie directory folder.
            $params = @{
                Path        = $OutputDirectory
                Name        = "$MovieFolderName"
                ItemType    = 'Directory'
                ErrorAction = 'SilentlyContinue'
            }

            # Create movie directory and then creates movie subfolder directories
            Write-Output "Created `"$MovieFolderName`" directory."
            New-Item @params | New-MovieSubFolders | Out-Null
        }
    }
}