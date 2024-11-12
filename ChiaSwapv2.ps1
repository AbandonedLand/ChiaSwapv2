function New-GridTradingTable {
    param (
        [decimal]$CurrentPrice,
        [decimal]$PriceDelta,
        [int]$NumberOfRows,
        [decimal]$FeeCharged,
        [decimal]$MaxRiskInXCH,
        [string]$tokenX,
        [string]$tokenY
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

        # Create an object for this row
        $row = [PSCustomObject]@{
            ID          = $i+1 
            TokenX      = $TokenX
            TokenY      = $TokenY
            PriceLevel  = [math]::Round($priceLevel, 2)
            BuyPrice    = [math]::Round($buyPrice, 2)
            BuyTotalX   = [math]::Round(($tokenXPerTrade*$buyPrice), 2)
            SellPrice   = [math]::Round($sellPrice, 2)
            SellTotalX   = [math]::Round(($tokenXPerTrade*$sellPrice), 2)
            OfferX      = $TokenXPerTrade
            
        
        }

        # Add row to array
        $gridRows += $row
    }

    # Output the array of grid rows
    return $gridRows
}



# Example usage
$grid = New-GridTradingTable  -TokenX "XCH" -TokenY "wUSDC.b" -CurrentPrice 16 -FeeCharged 0.3 -PriceDelta 5 -NumberOfRows 100 -MaxRiskInXCH 40
$grid | Format-Table -AutoSize

($grid.BuyTotalX | Measure-Object -Sum).Sum
($grid.SellTotalX | Measure-Object -Sum).Sum