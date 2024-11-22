using module .\BasicGrid.psm1


enum StrategyTypes {
    BasicGrid
    DexieRewardFarm
    SingleOfferRange
    Arbitrage
    TibetGrid
}


Function Get-Strategy {
    params(
        [Parameter(Mandatory = $true)]
        # [ValidateSet('BasicGrid','DexieRewardFarm','SingleOfferRange','Arbitrage','TibetGrid')]    # This is for the builder
        [string]$id
    )
    
    Connect-Mdbc ([Config]::config.database.connection_string) ([Config]::config.database.database_name) strategy
    $strategy =  get-mdbcdata @{_id=$id}

}


Function New-Strategy {
    
    $strategy = Read-SpectreSelection  -Message "Select a strategy type" -Choices ([StrategyTypes].GetEnumNames()) -PageSize (([StrategyTypes].GetEnumNames()).Count)

    $toreturn= $null

    switch ($strategy) {
        BasicGrid { $toreturn = [BasicGridStrategy]::build() }
        DexieRewardFarm {}
        SingleOfferRange {}
        Arbitrage {}
        TibetGrid {}
    }

    return $toreturn
}