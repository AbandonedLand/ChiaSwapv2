Class Config{
    static $config = @{

        # Database Configuration
    
        database= @{
            # Mongo DB Connection String
            connection_string = "."
    
            # Mongo DB Database Name
            database_name = "chiaswap"
        }
        
        offer = @{
    
            # Reuse your address for each offer
            reuse_puzhash = $true
    
            # Fee included with offer (in mojos:  1 mojo equals .000000000001 XCH)
            fee = 0
    
            # Automatically claim DBX at end of offers
            claim_rewards = $true
        }
        
        
    }
    
}
