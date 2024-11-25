using module .\Token.psm1
Class Wallet{

    static [pscustomobject] getWalletIdForToken([Token] $token){

        $json = @{
            asset_id = $token.id
        } | ConvertTo-Json
        $result = chia rpc wallet cat_asset_id_to_name $json | ConvertFrom-Json
        if(!$result){
            throw "Could not get coin info from wallet. [wallet]::getWalletIdForToken()"
        }
        return $result

    }
    
    static [pscustomobject] getCoinRecords(){

        $result = chia rpc wallet get_coin_records | ConvertFrom-Json
        if(!$result){
            throw "Could not get spendable coins from wallet. [wallet]::getSpendableCoinsForToken()"
        }
        return $result
    }

    static [pscustomobject] combineCoin($wallet_id,$number_of_coins,$target_coin_amount){
        $json = @{
            wallet_id=$wallet_id
            number_of_coins=$number_of_coins
            target_coin_amount = $target_coin_amount
            fee=0
        } | ConvertTo-Json
        $result = chia rpc wallet combine_coins $json | ConvertFrom-Json
        return $result

    }

    static [pscustomobject] splitCoin($wallet_id, $coin_id, $number_of_coins, $amount_per_coin){
        $json = @{
            wallet_id = $wallet_id
            target_coin_id = $coin_id
            number_of_coins = $number_of_coins
            amount_per_coin = $amount_per_coin
            fee = 0
        } | ConvertTo-Json

        $result = chia rpc wallet split_coins $json | ConvertFrom-Json
        if(!$result){
            throw "Could not get split coin. [wallet]::splitCoin()"
        }
        return $result
    }


}