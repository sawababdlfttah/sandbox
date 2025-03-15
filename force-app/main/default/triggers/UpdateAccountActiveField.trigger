trigger UpdateAccountActiveField on Contact (after insert, after update) {
    // Set to store Account IDs that need to be updated
    Set<Id> accountIdsToUpdate = new Set<Id>();

    // Map to store Account ID to a boolean indicating if it should be set to Active = No
    Map<Id, Boolean> accountActiveStatusMap = new Map<Id, Boolean>();

    // Loop through the contacts that were inserted or updated
    for (Contact con : Trigger.new) {
        // Check if the Contact is related to an Account
        if (con.AccountId != null) {
            // Add the Account ID to the set
            accountIdsToUpdate.add(con.AccountId);
        }
    }

    // Query all related Contacts for the Accounts in the set
    List<Contact> relatedContacts = [SELECT Id, AccountId, Level__c FROM Contact WHERE AccountId IN :accountIdsToUpdate];

    // Loop through the related Contacts
    for (Contact con : relatedContacts) {
        // Check if the Contact has Level = 'Primary'
        if (con.Level__c == 'Primary') {
            // If any Contact has Level = 'Primary', set the Account's Active field to 'Yes'
            accountActiveStatusMap.put(con.AccountId, true);
        } else if (con.Level__c == 'Secondary' && !accountActiveStatusMap.containsKey(con.AccountId)) {
            // If the Contact has Level = 'Secondary' and no Primary Contact exists, set the Account's Active field to 'No'
            accountActiveStatusMap.put(con.AccountId, false);
        }
    }

    // Query the Accounts that need to be updated
    List<Account> accountsToUpdate = [SELECT Id, Active__c FROM Account WHERE Id IN :accountIdsToUpdate];

    // Loop through the Accounts and update the Active field based on the map
    for (Account acc : accountsToUpdate) {
        if (accountActiveStatusMap.containsKey(acc.Id)) {
            acc.Active__c = accountActiveStatusMap.get(acc.Id) ? 'Yes' : 'No';
        }
    }

    // Update the Accounts
    if (!accountsToUpdate.isEmpty()) {
        update accountsToUpdate;
    }
}