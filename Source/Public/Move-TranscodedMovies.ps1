<#
.SYNOPSIS
Moves transcoded movie folders to the appropriate Movies directory.

.DESCRIPTION
This function moves transcoded movie folders to the Movies directory located on fixed volumes.
It ensures that only folders with files that haven't been modified in the last specified hours
are moved.  Empty folders are removed during the process.

.PARAMETER TranscodedFolder
Specifies the path to the location of transcoded movie folders ready to be moved.

.PARAMETER MovieDirectoryLocations
Specifies the path to the locations of destination movie folders ready to be moved.

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
            HelpMessage = "The directory path that contain the movie letters directories (ex. A-C, 0-9)."
        )]
        [ValidateScript(
            {
                Test-Path -Path $_
            }
        )]
        [String[]] $MovieDirectoryLocations,

        [Parameter(
            HelpMessage = "Skip folders that have LastWriteTime less than this many hours ago."
        )]
        [int] $HoursLastWrite = 20
    )
    begin {
        # In Windows looked at fixed volumes to see if they contain a folder named "Movies" on the root of drive.:
        if (-not($MovieDirectoryLocations) -and $IsWindows) {
            $MovieDirectoryLocations = Get-Volume
            | Where-Object { $_.DriveType -eq 'Fixed' -and (Test-Path "$($_.DriveLetter):\Movies") }
            | Select-Object @{label = "Path"; Expression = { "$($_.DriveLetter):\Movies" } }
        }

        # If no value for $MovieDirectoryLocations variable, throw error and exit script.
        if (-not($MovieDirectoryLocations)) {
            Write-Error -Message '$MovieDirectoryLocations variable was not defined and could not be determined.'
            exit 1
        }

        # Looks at the folders in each one of the Movies directories and figures out their ascii values.
        $MovieFolders = Get-ChildItem -Path $MovieDirectoryLocations
        # Make sure folder name matches regex value.  Which is a character followed by a dash (-) followed by another character.
        | Where-Object Name -Match '^[A-Za-z0-9]-[A-Za-z0-9]$'
        | Sort-Object FullName
        | Select-Object -Unique @{label = "Name"; Expression = { $_.Name.ToUpper() } }, FullName,
        # Get the first character ASCII value.
        @{label = "MinASCII"; Expression = { [int[]][char[]]($_.Name).ToUpper().replace('-', '')[0] } },
        # Get the last character ASCII value.
        @{label = "MaxASCII"; Expression = { [int[]][char[]]($_.Name).ToUpper().replace('-', '')[1] } }

        # List of movies in the TranscodedFolder directory.
        Write-Debug "Found Movies in Folder Lists. `n$($MovieFolders | Out-String)"

        # Gets list of folders that have files haven't been modified in $HoursLastWrite many hours.
        $Transcoded = Get-ChildItem $TranscodedFolder -Directory
        | Sort-Object FullName
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
    }

    process {
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
                    # Tell where movie folder is being moved to.
                    Write-Verbose "Destination directory $($Directory.FullName)"

                    # Move movie folder to destination directory and cleanup empty leftover folders.
                    Write-Verbose "Moving $($Movie.Name) to $($Directory.FullName)"
                    Move-Item -Path $Movie.FullName -Destination $Directory.FullName -ErrorAction Continue
                    | Where-Object { (Get-ChildItem $_ -Recurse -File).count -eq 0 }
                    | ForEach-Object { Remove-Item $_ -Recurse }
                }
            }
        }
    }
}