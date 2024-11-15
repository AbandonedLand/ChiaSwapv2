function Get-AllApiItems {
    param (
        [string]$baseUrl,            # Base URL of the API endpoint
        [int]$pageSize = 100,        # Number of items per page
        [string]$endPoint            # Api Endpoint
        
    )

    $allItems = @()                 # Array to store all items
    $page = 1                        # Start with the first page
    $morePages = $true               # Flag to check if more pages are available

    while ($morePages) {
        # Construct the URL with pagination parameters

        $url = -join($baseUrl,$endPoint,"?page_size=",$pageSize,"&page=",$page,"&type=cat")

        # Make the API request
        try {
            $response = Invoke-RestMethod -Uri $url -Method Get 
        }
        catch {
            Write-Error "Error fetching data: $_"
            return
        }

        # Append the current page items to the allItems array
        $allItems += $response.($endPoint)  # Adjust 'items' if the JSON structure is different

        # Check if the number of items returned is less than the page size (last page)
        if ($response.($endPoint).Count -lt $pageSize) {
            $morePages = $false
        }
        else {
            $page++  # Move to the next page
        }
    }

    return $allItems
}