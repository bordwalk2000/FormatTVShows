<#
.SYNOPSIS
Retrieves information about a specific season of a TV show from The Movie Database (TMDb).

.DESCRIPTION
This function calls the TMDb API to fetch detailed information about a specific season of a TV show, including the season's ID, name, air date, number of seasons, and episodes.

.PARAMETER TVShowID
The unique ID of the TV show for which season information is being retrieved. This parameter is mandatory.

.PARAMETER SeasonNumber
The season number of the TV show for which information is being retrieved. This parameter is mandatory.

.PARAMETER APIKey
The API key used to authenticate with the TMDb API. This parameter is optional if the API key is provided in another way.

.PARAMETER BaseURL
The base URL for the TMDb API. The default value is "https://api.themoviedb.org/3". This parameter is optional.

.EXAMPLE
Get-TheMovieDBTVShowSeasonInfo -TVShowID 1399 -SeasonNumber 1 -APIKey "your_api_key"

This command retrieves information about the first season of the TV show with ID 1399.

.NOTES
Author: Bradley Herbst
Created: February 10th, 2017

Ensure you have a valid TheMovieDB API key to use this function.
#>
Function Get-TheMovieDBTVShowSeasonInfo {
    param(
        [Parameter(
            Mandatory
        )]
        [int]
        $TVShowID,

        [Parameter(
            Mandatory
        )]
        [int]
        $SeasonNumber,

        [Parameter()]
        [string]
        $APIKey,

        [Parameter()]
        [string]
        $BaseURL = "https://api.themoviedb.org/3"
    )

    # Create TV Show Season URI
    $URI = "$BaseURL/tv/$($TVShowID)/season/$($SeasonNumber)?api_key=$APIKey"

    #Calls the API for TV Show Season Data
    $APIData = Invoke-WebRequest -Uri $URI -ErrorAction Stop
    $Results = $APIData.Content | ConvertFrom-Json
    | Select-Object id, name, air_date, number_of_seasons, episodes

    return $Results
}