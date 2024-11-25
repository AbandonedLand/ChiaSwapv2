using module .\Config.psm1


Class Strategy {


    Strategy(){

    }

    Strategy($id){
        Connect-Mdbc ([Config]::config.database.connection_string) ([Config]::config.database.database_name) strategy
        $properties =  get-mdbcdata @{_id=$id}
        foreach ($key in $properties.Keys) {
            # Dynamically add each property from the hashtable to the class instance
            $this | Add-Member -MemberType NoteProperty -Name $key -Value $properties[$key]
        }
    }



    deactive(){
        $this.isActive = $false
        $this.log("Making Strategy Inactive")
        $this.save()
    }

    activate(){
        $this.isActive = $true
        $this.log("Making Strategy Active")
        $this.save()
    }

    

    cancelOffers(){
        $trade_ids = @()
        $this.activeOffers.getEnumerator().Value | ForEach-Object {$trade_ids += [string]($_.offer.trade_record.trade_id)}

        $trade_ids | ForEach-Object {
            $json = @{
                trade_id = $_
                fee = 0
                secure=$true
            } | convertto-json
            $this.log("Canceling offer with trade_id $_")
            chia rpc wallet cancel_offer $json
        }
        
    }


}