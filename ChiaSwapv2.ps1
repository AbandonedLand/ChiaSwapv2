. .\classes\Config.ps1
. .\classes\TokenFactory.ps1
. .\classes\Dexie.ps1
. .\classes\Tibet.ps1
. .\functions\ApiHelper.ps1
. .\strategies\BasicGrid.ps1
. .\classes\Token.ps1
. .\classes\Wallet.ps1




Function run-amm{
    [CmdletBinding()]
    PARAM()
    process{
        $loop = 1
        while($true){
            $strategies = [BasicGridStrategy]::allActive()
            $strategies | ForEach-Object {
                
                Write-Host "Loop = $loop"
                Write-Host "---------------------------"
                $message = -join("Checking Offers for strategy: ", $_._id)
                Write-Host $message
                Write-Host "---------------------------"
                $message = -join("Current position is:", $_.currentPosition)
                Write-Host $message
                $_.checkActiveOffers()
                
                if(($loop % 5) -eq 0){
                Write-Host "---------------------------"
                Write-Host "Attempting to create bulk offers"
                Write-Host "---------------------------"
                    $_.createNOffersfromCurrentPosition($_.maxOffersFromPosition)
                }
                
                
            }
            $loop ++
            Write-Host "Done.  (sleep 2min)"
            start-sleep 120
        } 
    }
}
