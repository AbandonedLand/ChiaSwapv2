# ChiaSwap v2
## Description
Chia swap v2 is an an automated trading bot for the Chia Blockchain.  It currently lets you build a Basic Grid Stratey.

Example:
|Index|Base Price (Y/X)|Requested Y / Offered X|Offered Y / Requested X|Spread|
|--|--|--|--|--|
|9|19.80 |19.85 usd / 1 xch|19.75 usd / 1 xch|$0.10|
|10|20.00|20.05 usd / 1 xch|19.95 usd / 1 xch|$0.10|
|11|20.20|20.25 usd / 1 xch|20.15 usd / 1 xch|$0.10|

The strategy uses MongoDB and Dexie.Space to track offers.  Then when an offer is taken, it creates the next offer in line.  

For example, if index 10 Bid side (Offer Y / Request X) is taken, It will automaticaly create the Ask side for index 10 (Requested Y / Offered X) and the Bid side for index 9.

When the offers are created, they are put into the MongoDB database under the strategy collection.  It's strategy ID is tracked and all the offers currently active and completed are tracked.  This allows you to run multiple strategies in your wallet at once.

## Getting Started
Step 1: Install PowerShell 7.4+

https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.4

Step 2: Install MongoDB

https://www.mongodb.com/docs/manual/installation/

Step 3: Install needed PowerShell Modules (MDBC & PWSHSpectreConsole)
### MDBC

https://github.com/nightroman/Mdbc

```PowerShell
Install-Module -name MDBC
```
```PowerShell
Import-Module -name MDBC
```

### Spectre Console
https://pwshspectreconsole.com/guides/install/
```PowerShell
Install-Module PwshSpectreConsole -Scope CurrentUser
```

```PowerShell
Import-Module PwshSpectreConsole
```


Step 4: Clone this repository to your local computer.

Step 5: Load items into memory for this powershell session.

```PowerShell
CD CHIASWAPV2
. .\ChiaSwapv2.ps1
```

Step 6: Build Token list from Dexie
```PowerShell
[Token]::syncListWithDexie()
```

Step 7: Sync trading pairs from TibetSwap
```PowerShell
[Tibet]::syncPairsWithTibet()
```

Step 8: Build your first strategy.  

NOTE: THE ONLY WORKING STRATEGY IS BASICGRID.  The others are not created yet.

```PowerShell
# Assign the strategy object to a variable
$Strategy = New-Strategy

```

Step 9: Bootstrap the process by creating your first offers. You'll want to create an offer from the median index number of your trading grid.  This can be found by taking the anser from the "How many steps would you like" answer and dividing it by two.  The default was 100 steps, so 50 would be the median.

You'll need to know a little about coin management here.  If you accepted the defaults for number of offers to create at once, you'll create 5-6 offers requesting Token Y, and 5-6 offers requesting Token X.  You'll need that many coins on each side in the amounts large enough to cover the offers.  If you don't want to worry about that, set the strategy to only 1 offer on each side at a time.

```PowerShell
# $Strategy.createOffersFromPosition(MEDIAN INDEX)
$Strategy.createOffersFromPosition(50)
```

Step 10: Start your AMM.  Once your initial offers are posted to dexie from the step above, then you can run:
```PowerShell
Invoke-AMM
```

This will get all active strategies from MongoDB and check to see if the offers been taken from dexie.space every 2 minutes.  If so, it will automatically post the next offers.  

To stop the AMM press CTRL+Z

## Warning
This is a work in process.  It is possible to lose money with this.  

## Plans
I plan to create multiple trading strategies.  I also plan to move everything to the Spectre Console interface.  This will take some time to complete.
