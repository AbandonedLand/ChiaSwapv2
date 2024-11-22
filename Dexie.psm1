

Class Dexie{
    static [pscustomobject] GetIncentives(){

        $uri = "https://api.dexie.space/v1/incentives"
        return Invoke-RestMethod -Method Get -Uri $uri -MaximumRetryCount 5 -RetryIntervalSec 2
        
    }

    static [pscustomobject] GetIncentive($code){
        $incentives = [Dexie]::GetIncentives()
        $results = [pscustomobject]@{
            Bid = $incentives.incentives | Where-Object {$_.offered.code -eq $code}
            Ask = $incentives.incentives | Where-Object {$_.requested.code -eq $code}
        }
        $results.Bid | Add-Member -MemberType NoteProperty -Name p -Value ($results.Bid.marketPrice /1)
        return $results
    
    }

    static [array] GetAssets(){
        return Get-AllApiItems -baseUrl "https://dexie.space/v1/" -endPoint assets -pageSize 100
    }
    

    static [pscustomobject] createOffer($json){
        $json = $json | ConvertTo-Json

        $offer = chia rpc wallet create_offer_for_ids $json | ConvertFrom-Json
        if(!($offer)){
            throw "Offer failed to create"
        }
        return $offer
    }

    static [pscustomobject] takeOffer($dexieId){
        $uri = -join("https://dexie.space/v1/offers/",$dexieId)
        $response = Invoke-RestMethod -Uri $uri -Method Get -MaximumRetryCount 1 -RetryIntervalSec 2
        if(!($response)){
            throw "Could not get offer data"
        }
        $json = @{
            offer = ($response.offer.offer)
        } | ConvertTo-Json
        $chiaresponse = chia rpc wallet take_offer $json | ConvertFrom-Json
        return $chiaresponse
    }


    static [PSCustomObject] getStrategyActiveOfferStatus($strategy){
        $ids = @()
        $strategy.activeOffers.GetEnumerator() | ForEach-Object {
            $ids += $_.Key
        }
        $payload = @{'ids'=$ids}
        $results = Invoke-RestMethod -Method Post -Body ($payload | ConvertTo-Json) -Uri "https://api.dexie.space/v1/offersBatch" -ContentType "Application/json"
        return $results.offers | Sort-Object {$_.date_found} -Descending
    }
}