<#
.SYNOPSIS
Retrieves detailed information about a specific TV show from TheMovieDatabase (TMDb).

.DESCRIPTION
This function calls the TheMovieDatabase API to fetch detailed information about a specific TV show, including the show's name, first air date, number of seasons, and season details.

.PARAMETER TVShowID
The unique ID of the TV show for which information is being retrieved. This parameter is mandatory.

.PARAMETER APIKey
The API key used to authenticate with TheMovieDatabase API. This parameter is optional if the API key is provided in another way.

.PARAMETER BaseURL
The base URL for the TheMovieDatabase API. The default value is "https://api.themoviedb.org/3". This parameter is optional.

.EXAMPLE
Get-TheMovieDBTVShowInfo -TVShowID 1399 -APIKey "your_api_key"

This command retrieves detailed information about the TV show with ID 1399.

.NOTES
Author: Bradley Herbst
Created: February 10th, 2017

Ensure you have a valid TheMovieDB API key to use this function.
#>
Function Get-TheMovieDBTVShowInfo {
    param(
        [Parameter(
            Mandatory
        )]
        [int]
        $TVShowID,

        [Parameter()]
        [string]
        $APIKey,

        [Parameter()]
        [string]
        $BaseURL = "https://api.themoviedb.org/3"
    )

    # Create TV Show URI
    $URI = "$BaseURL/tv/$($TVShowID)?api_key=$APIKey"

    # Calls the API for TV Show Data
    $APIData = Invoke-WebRequest -Uri $URI -ErrorAction Stop
    $Results = $APIData.Content | ConvertFrom-Json
    | Select-Object name, first_air_date, number_of_seasons, seasons

    return $Results
}