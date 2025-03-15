public class AccountTriggerHandler {
    public static void handleTrigger(List<Account> newRecords, Map<Id, Account> oldRecords, Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate) {
        if (isBefore) {
            if (isInsert) {
                beforeInsert(newRecords);
            }
            if (isUpdate) {
                beforeUpdate(newRecords, oldRecords);
            }
        }
        if (isAfter) {
            if (isInsert) {
                afterInsert(newRecords);
            }
            if (isUpdate) {
                afterUpdate(newRecords);
            }
        }
    }

    private static void beforeInsert(List<Account> newAccounts) {
        System.debug('Before Insert Logic');
        // Add logic here
    }

    private static void beforeUpdate(List<Account> newAccounts, Map<Id, Account> oldAccounts) {
        System.debug('Before Update Logic');
        // Add logic here
    }

    private static void afterInsert(List<Account> newAccounts) {
        System.debug('After Insert Logic');
        // Add logic here
    }

    private static void afterUpdate(List<Account> newAccounts) {
        System.debug('After Update Logic');
        // Example: Update Opportunities when Industry changes
        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for (Account acc : newAccounts) {
            List<Opportunity> opps = [SELECT Id, Amount FROM Opportunity WHERE AccountId = :acc.Id];
            for (Opportunity opp : opps) {
                if (acc.Industry == 'Electronics') {
                    opp.Amount *= 1.1;
                    oppsToUpdate.add(opp);
                }
            }
        }

        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }
    }
    public static void Createcontact(List<Account> NewAccounts){
        List<Contact>   ContactToInsert = new List<Contact>();
        for ( Account acc : NewAccounts ){
            Contact con = new Contact( 
            Firstname= 'test trig',
             LastName= acc.Name,
                AccountId= acc.Id
            )	;
                ContactToInsert.add(con);
        }
     }
}