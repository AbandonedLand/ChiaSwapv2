. .\classes\Config.ps1
. .\classes\TokenFactory.ps1
. .\classes\Dexie.ps1
. .\classes\Tibet.ps1
. .\functions\ApiHelper.ps1
. .\strategies\BasicGrid.ps1
. .\classes\Token.ps1




Function run-amm{
    [CmdletBinding()]
    PARAM()
    process{
        
        $strategies = [BasicGridStrategy]::allActive()
        $strategies | ForEach-Object {
            Write-Host ""
            Write-Host "---------------------------"
            $message = -join("Checking Offers for strategy: ", $_._id)
            Write-Host $message
            Write-Host "---------------------------"
            $message = -join("Current position is:", $_.currentPosition)
            Write-Host $message
            $_.checkActiveOffers()
            Write-Host "---------------------------"
            Write-Host "Attempting to create offers"
            Write-Host "---------------------------"
            $_.createNOffersfromCurrentPosition($_.maxOffersFromPosition)
            Write-Host "Done.  (sleep 2min)"
        } 
    }
}
