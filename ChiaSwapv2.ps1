using module .\Config.psm1
using module .\Strategy.psm1
using module .\BasicGrid.psm1
using module .\Dexie.psm1
using module .\Token.psm1
using module .\StrategyBuilder.psm1
. .\Tibet.ps1


function Reset-Modules {
    #Remove-Module Tibet
    Remove-Module Token
    Remove-Module Dexie
    Remove-Module BasicGrid
    Remove-Module Strategy
    Remove-Module Config
}

. .\ApiHelper.ps1





Function Invoke-AMM{
    [CmdletBinding()]
    PARAM()
    process{
        $loop = 1
        while($true){
            $strategies = Get-ActiveStrategies
            $strategies | ForEach-Object {
                
                Write-Host "Loop = $loop"
                Write-Host "---------------------------"
                $message = -join("Checking Offers for strategy: ", $_._id)
                Write-Host $message
                Write-Host "Y Token is: $($_.TokenY.code)"
                Write-Host "Highest Bid position: $($_.highestbid())"
                Write-host "Lowest Ask position: $($_.lowestask())"
                Write-Host "There are $($_.activeOffers.count) Offers Active"
                Write-Host "There are $($_.completedOffers.count) Offers Completed"
                Write-Host "---------------------------"
                
                
                $_.checkActiveOffers()
                
                
            }
            $loop ++
            Write-Host "Done.  (sleep 2min)"
            start-sleep 120
        } 
    }
}

Function Get-Strategy($name){
    Connect-Mdbc ([Config]::config.database.connection_string) ([Config]::config.database.database_name) strategy
        $properties =  get-mdbcdata @{_id=$name}

        switch ($properties.Type) {
            "BasicGrid" { Return [BasicGridStrategy]::new($name) }
            Default {}
        }
}

Function Get-ActiveStrategies{
    $strategies = @()
    Connect-Mdbc ([Config]::config.database.connection_string) ([Config]::config.database.database_name) strategy
    $all = Get-MdbcData @{isActive = $true}
    foreach($strat in $all){
        $strategies += (Get-Strategy($strat._id))
    }
    return $strategies
}