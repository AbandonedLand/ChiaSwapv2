. .\classes\Config.ps1
. .\classes\TokenFactory.ps1
. .\classes\Dexie.ps1
. .\classes\Tibet.ps1
. .\functions\ApiHelper.ps1
. .\strategies\BasicGrid.ps1
. .\classes\Token.ps1




Function run-amm{
    $strategies = [ChiaStrategy]::allActive()
    $strategies | ForEach-Object {
        $_.checkActiveOffers()
    }
}
