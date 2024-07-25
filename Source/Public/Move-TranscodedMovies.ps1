<#
Requires -Modules Storage

.SYNOPSIS
Moves transcoded movie folders to the appropriate Movies directory.

.DESCRIPTION
This function moves transcoded movie folders to the Movies directory located on fixed volumes.
It ensures that only folders with files that haven't been modified in the last specified hours
are moved.  Empty folders are removed during the process.

.PARAMETER TranscodedFolder
Specifies the path to the location of transcoded movie folders ready to be moved.

.PARAMETER HoursLastWrite
Specifies the number of hours to skip folders that have LastWriteTime set to less than this many
hours ago. Default is 20 hours.

.EXAMPLE
PS> Move-TranscodedMovies -TranscodedFolder "C:\TranscodedMovies"

Moves transcoded movie folders from the specified path to the appropriate Movies directory,
considering the default HoursLastWrite of 20.

.EXAMPLE
PS> Move-TranscodedMovies -TranscodedFolder "C:\TranscodedMovies" -HoursLastWrite 12

Moves transcoded movie folders from the specified path to the appropriate Movies directory,
considering only folders with files that haven't been modified in the last 12 hours.

.NOTES
Author: Bradley Herbst
Created: Oct 13, 2021

Currently this function requires windows
#>
Function Move-TranscodedMovies {
    param(
        [Parameter(
            Mandatory,
            Position = 0,
            HelpMessage = "Path to the location of transcoded movie folders ready to be moved."
        )]
        [ValidateScript(
            {
                Test-Path -Path $_
            }
        )]
        [IO.DirectoryInfo] $TranscodedFolder,

        [Parameter(
            HelpMessage = "Skip folders that have LastWriteTime less than this many hours ago."
        )]
        [int] $HoursLastWrite = 20
    )

    # Looked at fixed volumes to see if they contain a folder named "Movies" on the root of drive
    # TODO: Requires Windows Storage module to run, so only currently a windows only function.
    $MovieDirectoryLocations = Get-Volume
    | Where-Object { $_.DriveType -eq 'Fixed' -and (Test-Path "$($_.DriveLetter):\Movies") }
    | Select-Object @{label = "MovieDirectories"; Expression = { "$($_.DriveLetter):\Movies" } }

    # Looks at the folders in each one of the Movies directories and figures out their ascii values.
    $MovieFolders = Get-ChildItem -Path $MovieDirectoryLocations.MovieDirectories
    | Select-Object @{label = "Name"; Expression = { $_.Name.ToUpper() } }, FullName,
    @{label = "MinASCII"; Expression = { [int[]][char[]]($_.Name).ToUpper().replace('-', '')[0] } },
    @{label = "MaxASCII"; Expression = { [int[]][char[]]($_.Name).ToUpper().replace('-', '')[1] } }
    | Sort-Object Name

    # List of movies in the TranscodedFolder directory.
    Write-Debug "Found Movies in Folder Lists. `n$($MovieFolders | Out-String)"

    # Gets list of folders that have files haven't been modified in $HoursLastWrite many hours.
    $Transcoded = Get-ChildItem $TranscodedFolder -Directory
    | Where-Object { $_.GetFiles().Count -ne 0 }
    | Where-Object {
        $null -eq (
            Get-ChildItem $_.FullName -File -Recurse
            | Where-Object {
                $_.LastWriteTime -gt (Get-Date).AddHours(-$HoursLastWrite)
            }
        )
    }

    # List of found movies that can be moved.
    Write-Debug "$($Transcoded.count) movies found to move. `n$($Transcoded.Name | Out-String)"

    # Loop though Transcoded movie list.
    foreach ($Movie in $Transcoded) {
        Write-Verbose "Processing $($Movie.Name)"

        # Remove Empty Folders
        Write-Verbose "Removing Empty Folders"
            Remove-EmptyDirectories $Movie

        # Move transcoded movie to correct Movie destination folder.
        foreach ($Directory in $MovieFolders) {
            if (
                ([int]$Movie.Name.ToUpper()[0] -ge $Directory.MinASCII) -and
                ([int]$Movie.Name.ToUpper()[0] -le $Directory.MaxASCII)
            ) {
                Write-Verbose "Moving $($Movie.Name) to $($Directory.FullName)"
                Move-Item -Path $Movie.FullName -Destination $Directory.FullName -ErrorAction Continue
            }
        }
    }
}