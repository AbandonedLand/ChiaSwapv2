. .\classes\Config.ps1

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
        if($i -eq 0){
            $nextBidPosition = "Stop"
        } else {
            $nextBidPosition = 'Subtract'
        }
        if($i -lt ($NumberOfRows -1)){
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


Class BasicGridStrategy{

    BasicGridStrategy($id){
        Connect-Mdbc ([Config]::config.database.connection_string) ([Config]::config.database.database_name) strategy
        $properties =  get-mdbcdata @{_id=$id}
        foreach ($key in $properties.Keys) {
            # Dynamically add each property from the hashtable to the instance
            $this | Add-Member -MemberType NoteProperty -Name $key -Value $properties[$key]
        }
    }

    static [BasicGridStrategy] build(){
        Connect-Mdbc ([Config]::config.database.connection_string) ([Config]::config.database.database_name) strategy
        $name = (New-Guid).Guid
        $TokenYcode = Read-Host "Enter Token Y Code"
        $TokenY = [TokenFactory]::code($TokenYcode)
        $TokenXcode = Read-Host "Enter Token X Code"
        $TokenX = ([TokenFactory]::code($TokenXcode))
        [decimal]$StartingPrice = Read-Host "Enter starting price"
        [decimal]$FeeCharged = Read-Host "Enter FeeCharged"
        [int]$NumberOfRows  = Read-Host "Enter NumberOfRows"
        [decimal]$MaxRiskInXCH  = Read-Host "MaxRiskinXch"
        [decimal]$PriceDelta  = Read-Host "Enter Price Delta"
        [ordered]@{
            _id = $name
            Type="BasicGrid"
            MinPrice = ($StartingPrice - $PriceDelta)
            MaxPrice = ($StartingPrice + $PriceDelta)
            InitialPrice = $StartingPrice
            TokenY = $TokenY
            TokenX = $TokenX
            FeeCharged = $FeeCharged
            MaxRiskInXCH = $MaxRiskInXCH
            InitialTokenX = [math]::round(($MaxRiskInXCH/2),12)
            InitialTokenY = ([math]::round($StartingPrice*([math]::round(($MaxRiskInXCH/2),12)),3))
            TradeTable = (New-GridTradingTable  -TokenX $TokenX -TokenY $TokenY -CurrentPrice $StartingPrice -FeeCharged $FeeCharged -PriceDelta $PriceDelta -NumberOfRows $NumberOfRows -MaxRiskInXCH $MaxRiskInXCH)
            isActive = $true
            minPosition = 0
            currentPosition = [decimal](($NumberOfRows/2)-0.5)
            maxPosition = ($NumberOfRows-1)
            activeOffers =@{}
            profitLoss=@()
            completedOffers = @{}
            createdAt = (get-date)
        } | Add-MdbcData -ErrorAction Ignore
    
        return [BasicGridStrategy]::new($name)
        
    }


    createOffersForCurrentPosition(){
        $bidPosition = [int]($this.currentPosition - 0.5)
        $askPosition = [int]($this.currentPosition + 0.5)

        $this.createOfferForPosition($bidPosition,"Bid")
        $this.createOfferForPosition($askPosition,"Ask")
    }

    

    static [array] allActive(){
        $strategies = @()
        Connect-Mdbc ([Config]::config.database.connection_string) ([Config]::config.database.database_name) strategy
        foreach($strat in (Get-MdbcData @{isActive=$true})){
            $strategies += [BasicGridStrategy]::new($strat._id)
        }
        return $strategies
    }

    createNOffersfromCurrentPosition([int]$n){
        $bidPosition = [int]($this.currentPosition - 0.5)
        $askPosition = [int]($this.currentPosition + 0.5)
        ($bidPosition - ($n-1))..$bidPosition | ForEach-Object {
            $check = $this.activeOffers.getEnumerator() | ForEach-Object {$_.Value | Where-Object {$_.position -eq $_ -and $_.side -eq "Bid"}}
            if(!$check){
                $this.createOfferForPosition($_,"Bid")
                Write-Information "Creating Bid at position $_"
                #start-sleep 2
            }
            
        }
        $askPosition..($askPosition + ($n-1)) | ForEach-Object {
            $check = $this.activeOffers.getEnumerator() | ForEach-Object {$_.Value | Where-Object {$_.position -eq $_ -and $_.side -eq "Ask"}}
            if(!$check){
                Write-Information "Creating Ask at position $_"
                $this.createOfferForPosition($_,"Ask")
                #start-sleep 2
            }
            
        }
    }

    createOfferForPosition([int]$position,[string]$side){
        if($side -notin "bid", "ask"){
            throw "Side must be either bid or ask"
        }
        if($position -ge $this.minPosition -AND $position -le $this.maxPosition){
            # force Title Case on Side
            $textInfo = (Get-Culture).TextInfo
            $side = $textInfo.ToTitleCase($side)


            # Check to see if offer exists
            $check = $this.activeOffers.getEnumerator() | ForEach-Object {$_.Value | Where-Object {$_.position -eq $position -and $_.side -eq $side}}

            if(!$check){
                
                
                
                    $json = @{
                        offer = ($this.TradeTable[$position].$side.offer)
                        fee=([Config]::config.offer.fee)
                        reuse_puzhash = ([Config]::config.offer.reuse_puzhash)
                    }

                    $offer = [Dexie]::createOffer($json)
                    if($offer){
                        $dexieResponse = $this.postOfferToDexie($offer)
                        if($dexieResponse){
                            $this.addActiveOffer($dexieResponse,$offer,$position,$side)
                        } else {
                            throw "Dexie did not process offer"
                        }
            
                    } else {
                        throw "Failed to create offer."
                    }
                
                
                #$offer = $this.makeOffer($json)
                
            } else {
                $message = -join("Offer exists for Position: ",$position," Side: ",$side)
                Write-Information $message
            }
        }
        
    }


    addActiveOffer($dexieResponse, $offer, $position, $side){
        if(!$this.activeOffers.($dexieResponse.id)){
            $this.activeOffers.($dexieResponse.id) = [ordered]@{
                position = $position
                side = $side
                dexieResponse = $dexieResponse
                offer = $offer
                createdAt = (Get-Date)
            }
            $this.save()
        }
        
    }

    

    [pscustomobject]postOfferToDexie($offer){
        $payload = @{
            offer = $offer.offer
            claim_rewards = ([Config]::config.offer.claim_rewards)
        } | ConvertTo-Json
        $response = Invoke-RestMethod -Uri 'https://api.dexie.space/v1/offers' -Method Post -Body $payload -ContentType "application/json" -RetryIntervalSec 5 -MaximumRetryCount 2 
        if(!($response)){
            throw "Error posting offer to dexie"
        }
        return $response
    }


    checkActiveOffers(){
        # Entry point to check offers and make changes if needed.
        $ids = @()
        $this.activeOffers.GetEnumerator() | ForEach-Object {
            $ids += $_.Key
        }
        if($ids){
            
            $response = $this.getDexieBulkOfferStatus($ids)
            foreach($offer in $response.offers){
                # Offer Taken
                if($offer.status -eq 4){
                    $this.offerTaken($offer)
                    $this.save()
                    
                }
                # Offer canceled or expired
                if($offer.status -eq 3 -OR $offer.status -eq 6){
                    $this.offerNotActive($offer)
                    $this.save()
                }
            }

        } else {
            Write-Information "No active IDs found"
        }
        
        
        
    }

    offerNotActive($offer){
        if(!$offer){
            throw "No offer found"
        }

        if($this.completedOffers.($offer.id)){
            throw "Offer already marked as completed"
        }
        if(!$this.activeOffers.($offer.id)){
            throw "No Active Offer found"
        }
        $this.activeOffers.remove($offer.id)
    }

    offerTaken($offer){
        if(!$offer){
            throw "No offer found"
        }

        if($this.completedOffers.($offer.id)){
            throw "Offer already marked as completed"
        }
        
        $active = $this.activeOffers.($offer.id)
        
        if(!$active){
            $message = -join("No active offer found for ",$offer.id)
            throw $message
        }

        $this.completedOffers.($offer.id) = @{
            'dexie_id' = $offer.id
            'position' = $active.position
            'side' = $active.side
            'offered' = $active.dexieResponse.offer.offered
            'requested' = $active.dexieResponse.offer.requested
            'date_found' = $offer.date_found
            'date_completed' = $offer.date_completed
            'trade_id' = $offer.trade_id
        }
        if($active.side -eq "Ask"){
            $this.currentPosition = $this.currentPosition + 1
        }

        if($active.side -eq "Bid"){
            $this.currentPosition = $this.currentPosition - 1
        }

        if(!($this.profitLoss | Where-Object {$_.dexieId -eq $offer.id})){

            $TokenX = $null
            $TokenY = $null
            if($active.dexieResponse.offer.offered | Where-Object {$_.code -eq $this.TokenX.code}){
                $TokenX = -($active.dexieResponse.offer.offered | Where-Object {$_.code -eq $this.TokenX.code}).amount
            } 
            if($active.dexieResponse.offer.offered | Where-Object {$_.code -eq $this.TokenY.code}){
                $TokenY = -($active.dexieResponse.offer.offered | Where-Object {$_.code -eq $this.TokenY.code}).amount
            }
            if($active.dexieResponse.offer.requested | Where-Object {$_.code -eq $this.TokenX.code}){
                $TokenX = ($active.dexieResponse.offer.requested | Where-Object {$_.code -eq $this.TokenX.code}).amount
            }
            if($active.dexieResponse.offer.requested | Where-Object {$_.code -eq $this.TokenY.code}){
                $TokenY = ($active.dexieResponse.offer.requested | Where-Object {$_.code -eq $this.TokenY.code}).amount
            }

            if(!$TokenX){
                throw "TokenX not found"
            }
            if(!$TokenY){
                throw "TokenY not found"
            }

            if($offer.rewards){
                $rewards = $offer.rewards
            } else {
                $rewards = 0
            }

            $pl = [ordered]@{
                _id = $offer.id
                dexieId = $offer.id
                strategy = $this._id
                rewards = $rewards
                tokenYcode = $this.TokenY.code
                tokenY = $TokenY
                tokenXcode = $this.TokenX.code
                tokenX = $TokenX
                price = ($tokenY / -($TokenX))
            }

            $this.profitLoss += $pl
            

            Connect-Mdbc ([Config]::config.database.connection_string) ([Config]::config.database.database_name) profitLoss
            $pl | Add-MdbcData

        }
        
        # Remove the offer data from active offers
        $this.activeOffers.remove($offer.id)

        # Create next set of offers.
        $this.createOffersForCurrentPosition()

    }

    
    



    [pscustomobject] getDexieBulkOfferStatus([array]$ids){
        $payload = @{'ids'=$ids}
        return Invoke-RestMethod -Method Post -Body ($payload | ConvertTo-Json) -Uri "https://api.dexie.space/v1/offersBatch" -ContentType "Application/json"
    }

    initiateStrategy(){
        
        Connect-Mdbc ([Config]::config.database.connection_string) ([Config]::config.database.database_name) strategy
        
        $ask = [int]($this.currentPosition + 0.5)
        $bid = [int]($this.currentPosition - 0.5)
    }

    
    [pscustomobject]checkDBXRewards(){
         # Entry point to check offers and make changes if needed.
         
         $ids = @()
         $this.activeOffers.GetEnumerator() | ForEach-Object {
             $ids += $_.Key
         }
         $response = [pscustomobject]@{}
         if($ids){
             
             $response = $this.getDexieBulkOfferStatus($ids)
         
        }
        return $response.offers

         
         
         
    }


    save(){
        Connect-Mdbc ([Config]::config.database.connection_string) ([Config]::config.database.database_name) strategy
        get-mdbcdata @{_id=($this._id)} -Set $this
    }

}