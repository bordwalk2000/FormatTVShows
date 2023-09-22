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