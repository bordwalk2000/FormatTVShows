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
    $SearchParams = [string]::Join('&',"query=$EscapedString","api_key=$APIKey","first_air_date_year=$Year")
    $SearchQuery = "$BaseURL/search/tv?$SearchParams"

    # Search for the TV Show and Pulls out top results
    $APIData = Invoke-WebRequest -Uri $SearchQuery -ErrorAction Stop
    $Results = ($APIData.Content | ConvertFrom-Json).results
    | Select-Object -First $ResultsCounts id, name, first_air_date, overview

    Return $Results
}