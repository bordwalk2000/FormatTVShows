<#
.SYNOPSIS
Renames TV Show files to a specific naming scheme and moves the files
to their correct seasons folder.

.DESCRIPTION
The scrips calls The Movie Database, themoviedb.org,  api to fetch
information aobut the TV Shows, Seasons, and Episodes.

It takes that data and creates Season folders for every season;
Renames the TV Shows episodes to the correct naming scheme; and
moves the episodes into the correct season folder.

After the script has finished processing the files, empty folders are removed.

.PARAMETER FolderPath
Specify the path to the TV Show folder where you want the files to be processed.

.PARAMETER TheMovieDB_API
Will need to have an themoviedb.org accouunt and setup to get a free api token.
This what allows the API calls to be authenticated in order to return data.

.PARAMETER TVShowID
If the search is not returning the correct TV Show or you just want to
manually specify one, you grab it off themoviedb.org website and the script
will use that ID when pulling information about the TV Show.

.PARAMETER Separator
Allows specifing the separator that is used when separating Season and Episode
numbers.  Example S01.E02

Allows the following characters to be used as a separator 'xX.-_ ' and a one
character limit.

Defaults to use the period of nothing is defined.

.PARAMETER NoSeparator
Will cause the script to not use a separator between Season and Episode
numbers.  Example S01E02

Will override anything defined in the -Separator parameter.

.INPUTS
None. You cannot pipe objects to format-tvshows.ps1.

.OUTPUTS
None. format-tvshows.ps1 does not generate any output.

.NOTES
Author: Bradley Herbst
Created: Febuary 9th, 2023

PROBLEMS: Doesn't currently handle processing two Episodes in one File.
It will rename the file to the first episode and you will need to manually fix
the name and specify the second episode.sDo you


# Script to recreate TV Show folder structure to allow testing of the script
param(
    [Parameter(Mandatory)][string] $SourceBackupFolder,
    [string] $DestinationFolder = [Environment]::GetFolderPath('UserProfile')
)

$Path = (New-Item -ItemType Directory -Path $DestinationFolder -Name $(
        Split-Path $SourceBackupFolder -Leaf) -ErrorAction Stop
).FullName
Get-ChildItem -Path $SourceBackupFolder -Recurse
| ForEach-Object {
    if ($_.Gettype().Name -eq 'DirectoryInfo') {
        New-Item -ItemType Directory -Path $(
            Join-Path -Path $Path -ChildPath (
                Split-Path $_.FullName
            ).Replace($SourceBackupFolder,'')
        ) -Name $_.BaseName
    }
    else {
        New-Item -Path $([WildcardPattern]::Escape($(
            Join-Path -Path $Path -ChildPath (Split-Path $_.FullName).Replace($SourceBackupFolder,'')
        ))) -Name $_.Name
    }
}

.EXAMPLE
./format-tvshows.ps1 -FolderPath 'Friends -TheMovieDB_API $env:api -Separator "x"

Basic example specify a specific separator.

.LINK
Git Repository Location
https://github.com/bordwalk2000/format-tvshows

#>
#Requires -Version 7
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $FolderPath,
    [ValidateNotNullOrEmpty()]
    [string] $TheMovieDB_API,
    [string] $TVShowID,
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('[xX\.\-_ ]')]
    [ValidateLength(1, 1)]
    [string] $Separator = ".",
    [switch] $NoSeparator,
    [switch] $Print
)

BEGIN {
    Function Find-TheMovieDBTVShowID {
        param(
            [Parameter(Mandatory)][string] $SearchString,
            [string] $APIKey,
            [int] $Year,
            [int] $ResultsCounts = 1
        )

        # TheMovieDB API Address
        $BaseURL = "https://api.themoviedb.org/3"

        # Escape String to be used in URL Search
        $EscapedString = [uri]::EscapeDataString($SearchString)

        # Create Search Query URL
        $SearchParams = [string]::Join('&',"query=$EscapedString","api_key=$APIKey","first_air_date_year=$Year")
        $SearchQuery = "$BaseURL/search/tv?$SearchParams"

        # Search for the TV Show and Pulls out top results
        $APIData = Invoke-WebRequest -Uri $SearchQuery -ErrorAction Stop
        $Results = ($APIData.Content | ConvertFrom-Json).results
        | Select-Object -First $ResultsCounts id, name, first_air_date, overview

        Return $Results
    }

    Function Get-TheMovieDBTVShowInfo {
        param(
            [Parameter(Mandatory)][int] $TVShowID,
            [string] $APIKey
        )

        # TheMovieDB API Address
        $BaseURL = "https://api.themoviedb.org/3"

        # Create TV Show URI
        $URI = "$BaseURL/tv/$($TVShowID)?api_key=$APIKey"

        # Calls the API for TV Show Data
        $APIData = Invoke-WebRequest -Uri $URI -ErrorAction Stop
        $Results = $APIData.Content | ConvertFrom-Json
        | Select-Object name, first_air_date, number_of_seasons, seasons

        Return $Results
    }

    Function Get-TheMovieDBSeasonInfo {
        param(
            [Parameter(Mandatory)][int] $TVShowID,
            [Parameter(Mandatory)][int] $SeasonNumber,
            [string] $APIKey
        )

        # TheMovieDB API Address
        $BaseURL = "https://api.themoviedb.org/3"

        # Create TV Show Season URI
        $URI = "$BaseURL/tv/$($TVShowID)/season/$($SeasonNumber)?api_key=$APIKey"

        #Calls the API for TV Show Season Data
        $APIData = Invoke-WebRequest -Uri $URI -ErrorAction Stop
        $Results = $APIData.Content | ConvertFrom-Json
        | Select-Object id, name, air_date, number_of_seasons, episodes

        Return $Results
    }

    # TheMovieDB API Address
    $BaseURL = "https://api.themoviedb.org/3"

    # System Check for Invalid File Name Characters
    $InvalidFileNameChars = [string]::join('',
        ([IO.Path]::GetInvalidFileNameChars())
    ) -replace '\\', '\\'
}

PROCESS {
    # Verifiy Folder Path is Valid
    if (-not (Test-Path $FolderPath)) {
        Write-Error 'Folder Path File Not Valid' -ErrorAction Stop
    }

    # Check if Able to Successfully Call TheMovieDB API
    try {
        Write-Verbose "Test API Connection"
        Write-Debug $(Invoke-RestMethod -Uri "$BaseURL/genre/movie/list?api_key=$TheMovieDB_API")
    }
    catch {
        $StatusCode = $_.Exception.Response.StatusCode
        Write-Debug API StatusCode: $StatusCode
        if ($StatusCode -eq 401) {
            $ErrorMessage = "Error Code: 401 Unauthroized.  " +
            "Unable to Connect to API."
            Write-Error $ErrorMessage -ErrorAction Stop
        }
        else {
            $ErrorMessage = "Expected 200, got $([int]$StatusCode)  " +
            "Unable to Connect to API."
            Write-Error $ErrorMessage -ErrorAction Stop
        }
    }

    # Find TheMovieDB TV Show ID if Not Specified
    if (!$TVShowID) {
        #Grab TV Show Name From Folder Name
        $FolderName = Split-Path $FolderPath -leaf

        # Check For Year Tag and Get Value Ready for Search Query if Found
        if ($FolderName -match '\s\(\d{4}\)') {
            $YearSearch = $FolderName -match '\s\(\d{4}\)' | Select-Object -First 1
            | ForEach-Object {
                # Returns Section of the String that the Regex Validated
                $Matches.Values -Replace '[^\d]'
            }
        }

        # Combine TV Show Name with Search Year Criteria
        $SearchString = $FolderName -replace '\s\(\d{4}\)',''

        # Splat Paramters Used for Find-TheMovieDBTVShowID Function
        $Params = @{
            APIKey = $TheMovieDB_API
            SearchString = $SearchString
        }

        # Add YearSearch if one was found.
        if ($YearSearch) { $Params.Year = $YearSearch }

        # Call Get API to get TV Show ID
        $Results = Find-TheMovieDBTVShowID @Params

        # Verify Results were Returned
        if ($Results.count -lt 1) {
            $ErrorMessage = "Unable to find results based on tv show search query: $SearchString`r`n" +
            "Either update folder name or supply TheMovieDB TV Show ID."
            Write-Error $ErrorMessage -ErrorAction Stop
        }

        # Populate TVShowID Variable
        $TVShowID = $Results.ID
        Write-Verbose "TV Show TheMovieDB ID: $TVShowID"
    }

    # Get TV Show Information
    $TVShowInfo = Get-TheMovieDBTVShowInfo -TVShowID $TVShowID -APIKey $TheMovieDB_API

    # Move 'The/A/An' to the End of the Title
    $FormatedTVShowName = $TVShowInfo.name -replace '^(the|a|an) (.*)$', '$2, $1'

    # Remove Colon from the Name; Not a Supported File Name Character on Windows
    $FormatedTVShowName = $FormatedTVShowName -Replace (': ', ' - ')

    # Replace Open Parentheses with Dash
    $FormatedTVShowName = $FormatedTVShowName -Replace (' \(', ' - ')

    # Remove Special Characters Not Supported On Different Operating Systems As Valid File Name Characters.
    $FormatedTVShowName = $FormatedTVShowName -Replace '[?(){}]'

    # Remove Colon from the Name; Not a Supported Windows Filename Character.
    $FormatedTVShowName = $FormatedTVShowName -replace "[$InvalidFileNameChars]", ''

    # Grab Only the Year from the First Aired Date
    $FirstedAiredYear = $TVShowInfo.first_air_date.Split('-')[0]

    # Put TV Show Folder Name String Together.
    $TVShowFolderName = "$($FormatedTVShowName) ($FirstedAiredYear)"
    Write-Debug "TV Show Folder Name: $TVShowFolderName"

    # Define Variable for Path to Newly Named Folder
    $UpdatedFolderPath = (
        Join-Path -Path (Split-Path -Path $FolderPath -Parent
        ) -ChildPath $TVShowFolderName)

    # Checks Folder Name is Different From New Name
    if ($(Split-Path -Path $FolderPath -Leaf) -ne $TVShowFolderName) {
        # Verify New Name Folder Doesn't Already Exists
        if (-not (Test-Path $UpdatedFolderPath)) {
            # Rename TV Show Folder
            Rename-Item -Path $FolderPath -NewName $TVShowFolderName
        }
        else {
            $ErrorMessage = "Folder already exists named '$UpdatedFolderPath' `r`n" +
            "Please remove or rename existing folder then rerun the script."
            Write-Error $ErrorMessage -ErrorAction Stop
        }
    }

    # Processes the Season Data in the TV Show Info Results
    $TVShowInfo.seasons
    | Sort-Object season_number
    | ForEach-Object {
         Write-Verbose "Processing Season $("{0:D2}" -f ([int]$_.season_number))"

        # Create Season Folder if it Doesn't Exist with 2-Digit Season Number
        if (-not(
                Test-Path -Path $(
                    Join-Path -Path $UpdatedFolderPath `
                        -ChildPath $("\Season {0:D2}" -f ([int]$_.season_number))
                )
            )) {
            New-Item -ItemType Directory -Path $(
                Join-Path -Path $UpdatedFolderPath `
                    -ChildPath $("\Season {0:D2}" -f ([int]$_.season_number))
            )
        }

        # Define Parameters to be Used in Get-TheMovieDBSeasonInfo Function
        $Params = @{
            TVShowID     = $TVShowID
            SeasonNumber = $_.season_number
            APIKey       = $TheMovieDB_API
        }
        # Call API to Get Season Info and Processes Data on the Episodes
            (Get-TheMovieDBSeasonInfo @Params).episodes
        | Sort-Object episode_number
        | ForEach-Object {
            # Creates String for Specifying 2-Digit Season and Episode Numbers
            $FullEpisodeNumber =
            $("S{0:D2}" -f ([int]$_.season_number)) +
            $(if (-not($NoSeparator)) { $Separator }) +
            $("E{0:D2}" -f ([int]$_.episode_number))
            Write-Verbose "Processing Episode $FullEpisodeNumber"

            # Assign Episode Name to Variable
            $EpisodeTitle = $_.name
            Write-Debug "Original Episode Title: $EpisodeTitle"

            # Replace Colon with Dash
            $EpisodeTitle = $EpisodeTitle -Replace (': ', ' - ')

            # Replace Colon in Middle of String with UniCode Colon Character
            $EpisodeTitle = $EpisodeTitle -Replace (':','꞉')

            # Replace Open Parentheses with Dash
            $EpisodeTitle = $EpisodeTitle -Replace (' \(', ' - ')

            # Remove Special Characters Not Supported On Different Operating Systems As Valid File Name Characters.
            $EpisodeTitle = $EpisodeTitle -Replace '[?(){}]'

            # Verify No Invalid File Name Characters in Episode Name
            $EpisodeTitle = $EpisodeTitle -replace "[$InvalidFileNameChars]", ''
            Write-Debug "Filtered Episode Title: $EpisodeTitle"

            # Finds the Correct Episode File by Matching Season & Episode Number
            # Against the Currently Processed Episode and Renames the File
            Get-ChildItem -Path $UpdatedFolderPath -File -Recurse
            | Where-Object {
                (
                    $_.Name -match $(
                            ($FullEpisodeNumber -match '[sS]\d{2}')
                        | Select-Object -First 1
                        # Returns Section of the String that the Regex Validated
                        | ForEach-Object { $Matches.Values }
                    )
                ) -and
                (
                    $_.Name -match $(
                            ($FullEpisodeNumber -match '[eE]\d{2}')
                        | Select-Object -First 1
                        # Returns Section of the String that the Regex Validated
                        | ForEach-Object { $Matches.Values }
                    )
                )
            }
            # Rename the File Found to Correct Name Format
            | ForEach-Object {
                $NewName = ($TVShowInfo.name,$FullEpisodeNumber,$EpisodeTitle -join ' ') + $($_.extension)
                try {
                    Rename-Item -Path $_ -NewName $NewName -ErrorAction Stop -PassThru
                    Write-Debug "Renamed File Name: $NewName"
                }
                catch {
                    Write-Error -Message "Unable to Rename / Moving File to $($TVShowInfo.name,$FullEpisodeNumber,$EpisodeTitle -join ' ')"
                    Write-Error -Message "Error Reason: $($Error[0].CategoryInfo.Reason)"
                }
            }
            # Moves File to Correct Season Folder
            | Move-Item -Destination $(
                Join-Path -Path $UpdatedFolderPath `
                    -ChildPath $(
                    "Season {0:D2}" -f ([int]$FullEpisodeNumber.Substring(1, 2))
                )
            ) -ErrorAction Continue
        }
    }
}

END {
    # Removes Empty Folders
    Write-Verbose "Remove Empty Folders"
    Get-ChildItem -Path $UpdatedFolderPath -Recurse
    | Where-Object {
        $_.PSIsContainer -and
        @(Get-ChildItem -LiteralPath $_.Fullname -Recurse
            | Where-Object { -not($_.PSIsContainer) }).Length -eq 0
    }
    | Remove-Item

    # Return Successful Exit Code
    Exit 0
}