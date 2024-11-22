using module .\Config.psm1
using module .\Dexie.psm1
using module .\TokenFactory.psm1

Class Token{
    [string]$id
    [string]$code
    [string]$name
    [int64]$decimalPlaces

    Token($code){
        Connect-Mdbc ([Config]::config.database.connection_string) ([Config]::config.database.database_name) assets
        $db = Get-MdbcData @{codeLower=([string]$code.toLower())}
        if(!$db){
            Throw "Could not find token.  [Token]::new(code)"
        }
        $this.id = $db._id
        $this.code = $code
        $this.name = $db.name
        $this.decimalPlaces = $db.decimalPlaces
    }

    static [Token] code($code){
        return [Token]::new($code)
    }

    static [string[]] incentivizedTokens(){
        return @(
            'DBX'
            'HOA'
            'SBX'
            'wUSDC'
            'wUSDC.b'
            'more'    
        )
    }

    static [pscustomobject] selectBasicY(){
        $selection = Read-SpectreSelection -Message "Which token do you wish to trade?" -Choices ([Token]::incentivizedTokens()) -PageSize (([Token]::incentivizedTokens()).Count)
        $token = $null
        switch ($selection) {
            more { $token = [Token]::selectAdvancedY() }
            Default { $token = [TokenFactory]::code($selection)}
        }
        return $token
    }

    static [pscustomobject] selectAdvancedY(){
        $response = Read-SpectreText -Message "Enter the code for the Token"
        return [TokenFactory]::code($response)
    }

    static [pscustomobject] selectBasicX(){
        Connect-Mdbc ([Config]::config.database.connection_string) ([Config]::config.database.database_name) assets
        $selection = Read-SpectreSelection -Message "Which token do you wish to trade?" -Choices @('XCH','other')
        $token = $null
        switch ($selection) {
            more { $token = [Token]::selectAdvancedY() }
            Default { $token = [TokenFactory]::code($selection)}
        }
        return $token
    }


    [decimal] getTibetMedianPrice(){
        # Get quote from tibet
        $prices = $this.getTibetQuote(1)

        $avgPrive = ((($prices.buy.amount_in + $prices.sell.amount_out)/2)/$this.decimalPlaces)

        return [Math]::round($avgPrive,3)
    }
  
    [pscustomobject]incentives(){

        return [Dexie]::GetIncentive($this.code)
    }

    # Sync the local database with Dexie's CAT2 token list
    static [void] syncListWithDexie(){
        Connect-Mdbc ([Config]::config.database.connection_string) ([Config]::config.database.database_name) assets
        $items = [Dexie]::GetAssets()
        $items += @{
            '_id' = "1"
            "id" = "1"
            'code'='XCH'
            'name'='XCH'
            'codeLower'='xch'
            'decimalPlaces'=1000000000000
        } 
        $date = Get-Date
        $items | ForEach-Object{
            $_ | Add-Member -MemberType NoteProperty -Name "_id" -Value $_.id
            $_ | Add-Member -MemberType NoteProperty -Name "updatedAt" -Value $date
            $_ | Add-Member -MemberType NoteProperty -Name "decimalPlaces" -Value 1000
            $_ | Add-Member -MemberType NoteProperty -Name "codeLower" -Value ([string]($_.code).tolower())
    
            $check = Get-MdbcData @{_id = $_._id}
            if($check){
                Get-MdbcData @{_id = $_._id} -Set $_
            } else {
                $_ | Add-MdbcData
            }
        }
        
    }

    [pscustomobject]getTibetQuote($xch){
        $amount = [int64]($xch*1000000000000)
        Connect-Mdbc ([Config]::config.database.connection_string) ([Config]::config.database.database_name) tibet

        $pair_id = Get-MdbcData @{_id = $this.id}
        $sell = -join("https://api.v2.tibetswap.io/quote/",$pair_id.pair_id,"?amount_in=",$amount,"&xch_is_input=true&estimate_fee=false")
        $buy = -join("https://api.v2.tibetswap.io/quote/",$pair_id.pair_id,"?amount_out=",$amount,"&xch_is_input=false&estimate_fee=false")
        $toSell = Invoke-RestMethod $sell -Method Get -MaximumRetryCount 5 -RetryIntervalSec 2
        $toSell | Add-Member -Name Price -MemberType NoteProperty -Value ([Math]::round((($toSell.amount_out/1000)/($toSell.amount_in/1000000000)),2))
        $toBuy = Invoke-RestMethod $buy -Method Get -MaximumRetryCount 5 -RetryIntervalSec 2
        $toBuy | Add-Member -Name Price -MemberType NoteProperty -Value ([Math]::round((($toBuy.amount_in/1000)/($toBuy.amount_out/1000000000000)),2))
        return [pscustomobject]@{
            buy = $toBuy
            sell= $toSell
        }

    }

}