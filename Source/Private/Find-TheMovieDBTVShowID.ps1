<#
.SYNOPSIS
    Searches for TV show IDs on The Movie Database (TMDb) based on a search string.

.DESCRIPTION
    This function calls the TMDb API to search for TV shows based on a provided search string. It returns the ID, name, first air date, and overview of the top results.

.PARAMETER SearchString
    The search string used to find TV shows. This parameter is mandatory.

.PARAMETER APIKey
    The API key used to authenticate with the TMDb API. This parameter is optional if the API key is provided in another way.

.PARAMETER Year
    The year of the first air date to filter the search results. This parameter is optional.

.PARAMETER ResultsCounts
    The number of top results to return. The default value is 1. This parameter is optional.

.PARAMETER BaseURL
    The base URL for the TMDb API. The default value is "https://api.themoviedb.org/3". This parameter is optional.

.EXAMPLE
    Find-TheMovieDBTVShowID -SearchString "Breaking Bad" -APIKey "your_api_key" -Year 2008 -ResultsCounts 1

    This command searches for the TV show "Breaking Bad" that first aired in 2008 and returns the top result.

.NOTES
    Ensure you have a valid TheMovieDB API key to use this function.
#>
Function Find-TheMovieDBTVShowID {
    param(
        [Parameter(Mandatory)][string] $SearchString,
        [string] $APIKey,
        [int] $Year,
        [int] $ResultsCounts = 1,
        [string] $BaseURL = "https://api.themoviedb.org/3"
    )

    # Escape String to be used in URL Search
    $EscapedString = [uri]::EscapeDataString($SearchString)

    # Create Search Query URL
    $SearchParams = [string]::Join('&', "query=$EscapedString", "api_key=$APIKey", "first_air_date_year=$Year")
    $SearchQuery = "$BaseURL/search/tv?$SearchParams"

    # Search for the TV Show and Pulls out top results
    $APIData = Invoke-WebRequest -Uri $SearchQuery -ErrorAction Stop
    $Results = ($APIData.Content | ConvertFrom-Json).results
    | Select-Object -First $ResultsCounts id, name, first_air_date, overview

    return $Results
}