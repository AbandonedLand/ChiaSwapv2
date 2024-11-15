

Class Dexie{
    static [pscustomobject] GetIncentives(){

        $uri = "https://api.dexie.space/v1/incentives"
        return Invoke-RestMethod -Method Get -Uri $uri -MaximumRetryCount 5 -RetryIntervalSec 2
        
    }

    static [array] GetIncentive($code){
        $incentives = [Dexie]::GetIncentives()

        return $incentives.incentives | Where-Object {$_.offered.code -eq $code -or $_.requested.code -eq $code}
    
    }

    static [array] GetAssets(){
        return Get-AllApiItems -baseUrl "https://dexie.space/v1/" -endPoint assets -pageSize 100
    }
    
}