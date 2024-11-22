using module ./Config.psm1

Class TokenFactory{

    static [pscustomobject] code($code){
        Connect-Mdbc ([Config]::config.database.connection_string) ([Config]::config.database.database_name) assets
        
        $db = Get-MdbcData @{code=$code}
        
        return $db    
    }
    static [pscustomobject] id($id){
        Connect-Mdbc ([Config]::config.database.connection_string) ([Config]::config.database.database_name) assets
        $db = Get-MdbcData @{id=$id}
        return $db    
    }
}