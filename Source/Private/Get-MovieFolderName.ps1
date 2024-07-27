<#
.SYNOPSIS
Formats movie titles into valid folder names based on TheMovieDB API search results.

.DESCRIPTION
This function takes a movie title (or titles) as input, searches for the movie(s) on TheMovieDB, and formats the titles into valid folder names. The function handles common issues such as moving articles ("The", "A", "An") to the end of the title, removing unsupported characters for Windows file names, and appending the release year.

.PARAMETER MovieSearchString
The movie title(s) to search for. This parameter is mandatory and can be provided via the pipeline or by property name.

.PARAMETER TheMovieDB_API
The API key used to authenticate with TheMovieDB API. This parameter is mandatory.

.PARAMETER BaseURL
The base URL for TheMovieDB API. The default value is "https://api.themoviedb.org/3".

.EXAMPLE
Get-MovieFolderName -MovieSearchString "The Matrix" -TheMovieDB_API "your_api_key"
This command formats the movie title "The Matrix" into a valid folder name using TheMovieDB API.

.EXAMPLE
"The Godfather", "Inception" | Get-MovieFolderName -TheMovieDB_API "your_api_key"
This command formats multiple movie titles into valid folder names using TheMovieDB API.

.INPUTS
[string[]] $MovieSearchString
[string] $TheMovieDB_API
[string] $BaseURL

.OUTPUTS
System.String
Returns a formatted string for the movie folder name.

.NOTES
The function relies on the Find-TheMovieDBMovie function to query TheMovieDB API.
Ensure that the API key is valid and has the necessary permissions.

.LINK
https://developers.themoviedb.org/3/getting-started/introduction
#>
Function Get-MovieFolderName {
    param (
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias("Name")]
        [string[]]
        $MovieSearchString,

        [Parameter(
            Mandatory
        )]
        [string]
        $TheMovieDB_API,

        [Parameter()]
        [string]
        $BaseURL = "https://api.themoviedb.org/3"
    )

    process {
        foreach ($Movie in $MovieSearchString) {
            # Pull data from TheMovieDB API
            $QueryResults = Find-TheMovieDBMovie -SearchString $Movie -APIKey $TheMovieDB_API

            # Move 'The/A/An' to the End of the Title
            $FormattedMoveTitle = $QueryResults.Title -replace '^(the|a|an) (.*)$', '$2, $1'

            # Remove Colon from the Name; Not a Supported File Name Character on Windows
            $FormattedMoveTitle = $FormattedMoveTitle -Replace (': ', ' - ')

            # Replace Open Parentheses with Dash
            $FormattedMoveTitle = $FormattedMoveTitle -Replace (' \(', ' - ')

            # Remove Special Characters Not Supported On Different Operating Systems As Valid File Name Characters.
            $FormattedMoveTitle = $FormattedMoveTitle -Replace '[?(){}]'

            # Remove Colon from the Name; Not a Supported Windows Filename Character.
            if ($IsWindows) {
                $FormattedMoveTitle = $FormattedMoveTitle -replace "[$InvalidFileNameChars]", ''
            }

            # Grab Year Movie Came Out
            $MovieYear = '{0:yyyy}' -f [DateTime]$QueryResults.release_date

            # Create String for Movie Folder Name
            $MovieFolderString = "$FormattedMoveTitle ($MovieYear)"

            return $MovieFolderString
        }
    }
}