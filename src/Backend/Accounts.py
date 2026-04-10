class Accounts:

    def __init__(self, dateOpened, bank, accountName, transactions):
        self.dateOpened = dateOpened
        self.bank = bank 
        self.accountName = accountName
        self.transactions = transactions

        
    def getAccount(self):
        return f"{self.bank} + {self.accountName}"
    

    def getMoreDetails(self):
        return f"Account Opened: {self.dateOpened}"
#---------------------------------------------------------------------------------------------------------
"""
POSSIBLY DELETE, useful on how account connection works {
After the user finishes signing in through Plaid Link, Plaid gives the frontend a public token. Your backend sends that to Plaid and gets back an access token (and item_id). You use the access token on server-side Plaid calls to pull accounts, balances, transactions, etc. for that linked bank.
Don’t: send the access token to the browser or treat the public token as long-lived—it’s only for that one exchange.
}
//shouldnt defaulty go in this file
"""
        


    



    

    



    

    
    
