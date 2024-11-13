Class TokenFactory{

    static [pscustomobject] code($code){
        Connect-Mdbc . chiaswap assets
        
        $db = Get-MdbcData @{code=$code}
        
        return $db    
    }
    static [pscustomobject] id($id){
        Connect-Mdbc . chiaswap assets
        $db = Get-MdbcData @{id=$id}
        return $db    
    }
}

Class Token{
    $id
    $code
    $name
    $decimalPlaces
}

Function Build-AssetCollection{
    Connect-Mdbc . chiaswap assets
    $items = Get-AllApiItems -baseUrl "https://dexie.space/v1/" -endPoint assets -pageSize 100
    $items += @{
        '_id' = "1"
        "id" = "1"
        'code'='XCH'
        'name'='XCH'
        'decimalPlaces'=1000000000000
    } 
    $date = Get-Date
    $items | ForEach-Object{
        $_ | Add-Member -MemberType NoteProperty -Name "_id" -Value $_.id
        $_ | Add-Member -MemberType NoteProperty -Name "updatedAt" -Value $date
        $_ | Add-Member -MemberType NoteProperty -Name "decimalPlaces" -Value 1000

        $check = Get-MdbcData @{_id = $_._id}
        if($check){
            Get-MdbcData @{_id = $_._id} -Set $_
        } else {
            $_ | Add-MdbcData
        }
    }
    
}

function New-GridTradingTable {
    param (
        [decimal]$CurrentPrice,
        [decimal]$PriceDelta,
        [int]$NumberOfRows,
        [decimal]$FeeCharged,
        [decimal]$MaxRiskInXCH,
        $tokenX,
        $tokenY
    )

    $MaxPrice = $CurrentPrice + $PriceDelta
    $MinPrice = $CurrentPrice - $PriceDelta

    # Calculate the price step based on min, max, and number of rows
    $priceStep = ($MaxPrice - $MinPrice) / ($NumberOfRows - 1)
    $spreadFactor = $FeeCharged / 100
    
    $tokenXPerTrade = [Math]::Round(($MaxRiskInXCH/$NumberOfRows),3)
    # Initialize an array to hold grid rows
    $gridRows = @()
    

    # Loop to generate each grid row
    for ($i = 0; $i -lt $NumberOfRows; $i++) {
        # Calculate price level
        $priceLevel = $MinPrice + ($i * $priceStep)
        
        # Apply the spread to calculate buy and sell prices
        $buyPrice = $priceLevel * (1 - $spreadFactor)
        $sellPrice = $priceLevel * (1 + $spreadFactor)

        $currentPosition = $i+1
        if($i -lt 1){
            $nextBidPosition = "Stop"
        } else {
            $nextBidPosition = 'Subtract'
        }
        if($i -lt 99){
            $nextAskPosition = "Add"
        } else {
            $nextAskPosition = 'Stop'
        }


        # Create an object for this row
        $row = [PSCustomObject]@{
            ID          = $currentPosition
            Price       = [math]::Round($priceLevel, 2)
            Bid         = [ordered]@{
                price = ([math]::Round($buyPrice, 2))
                tokenX = ([math]::Round($TokenXPerTrade,3))
                tokenY = ([math]::Round(($tokenXPerTrade*$buyPrice),3))
                offer = [ordered]@{
                    ($tokenY.id) = (-1*[int64][math]::Round(($tokenXPerTrade*$buyPrice*$tokenY.decimalPlaces)))
                    ($tokenX.id) = ([int64]($TokenXPerTrade*$tokenX.decimalPlaces))  
                }
                side = "Bid"
                currentPosition = $currentPosition
                nextPosition = $nextBidPosition
                arrayIndex = $i
                
                
            }
            Ask = [ordered]@{
                price = ([math]::Round($sellPrice, 2))
                tokenX = ([math]::Round($TokenXPerTrade,3))
                tokenY = ([math]::Round(($tokenXPerTrade*$sellPrice),3))
                offer = [ordered]@{
                    ($tokenY.id) = ([int64][math]::Round(($tokenXPerTrade*$sellPrice*$TokenY.decimalPlaces)))
                    ($tokenX.id) =  (-1*([int64]($TokenXPerTrade*$tokenX.decimalPlaces)))
                }
                side = "Ask"
                currentPosition = $currentPosition
                nextPosition = $nextAskPosition
                arrayIndex = $i
                
            }

        }

        # Add row to array
        $gridRows += $row
    }

    # Output the array of grid rows
    return $gridRows
}




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

$grid = New-GridTradingTable  -TokenX ([TokenFactory]::code("XCH")) -TokenY ([TokenFactory]::code("wUSDC.b")) -CurrentPrice 16 -FeeCharged 0.3 -PriceDelta 5 -NumberOfRows 100 -MaxRiskInXCH 40


function New-ChiaSwapStrategy{
    param(
        [string] $name,
        $TokenY,
        $TokenX = [TokenFactory]::code("XCH"),
        [decimal]$StartingPrice,
        [decimal]$FeeCharged,
        [int]$NumberOfRows,
        [decimal]$MaxRiskInXCH,
        [decimal]$PriceDelta
    )

    Connect-Mdbc . chiaswap strategy
    

    [ordered]@{
        _id = $name
        TokenY = $TokenY
        TokenX = $TokenX
        FeeCharged = $FeeCharged
        MaxRiskInXCH = $MaxRiskInXCH
        InitialTokenX = [math]::round(($MaxRiskInXCH/2),12)
        InitialTokenY = ([math]::round($StartingPrice*([math]::round(($MaxRiskInXCH/2),12)),3))
        TradeTable = (New-GridTradingTable  -TokenX $TokenX -TokenY $TokenY -CurrentPrice $StartingPrice -FeeCharged $FeeCharged -PriceDelta $PriceDelta -NumberOfRows $NumberOfRows -MaxRiskInXCH $MaxRiskInXCH)
        isActive = $true
        currentPosition = [decimal](($NumberOfRows/2)-0.5)
        activeOffers =@()
        completedOffers = @()
        createdAt = (get-date)
    } | Add-MdbcData -ErrorAction Ignore

    [ChiaStrategy]::new($name)

}


Class ChiaStrategy{

    $strategyId
    $strategy

    ChiaStrategy($strategyId){
        Connect-Mdbc . chiaswap strategy
        $this.strategyId = $strategyId
        $this.strategy = get-mdbcdata @{_id=$strategyId}
    }

    createOfferForPosition($position,$side){

    }

    save(){
        get-mdbcdata @{_id=($this.strategyId)} -Set $this.strategy
    }


}

$strategy = New-ChiaSwapStrategy -name usdcbgrid -TokenY ([TokenFactory]::code('wUSDC.b')) -StartingPrice 14.51 -FeeCharged 0.3 -NumberOfRows 100 -PriceDelta 4.51 -MaxRiskInXCH 40

