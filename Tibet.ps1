Class TibetSwap{

    static [void] syncPairsWithTibet(){
        $uri = 'https://api.v2.tibetswap.io/tokens'
        $response = Invoke-RestMethod -Uri $uri -Method Get

        Connect-Mdbc ([Config]::config.database.connection_string) ([Config]::config.database.database_name) tibet
        $response | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name "_id" -Value $_.asset_id
            $check = Get-MdbcData @{_id = $_._id}
            if($check){
                Get-MdbcData @{_id = $_._id} -Set $_
            } else {
                $_ | Add-MdbcData
            }

        }

    }

}