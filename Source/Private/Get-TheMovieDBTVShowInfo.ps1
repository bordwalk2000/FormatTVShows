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