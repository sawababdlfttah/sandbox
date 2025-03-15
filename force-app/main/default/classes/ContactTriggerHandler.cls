//////////// check same fields in 2 RT and updat another fields in another object example contact and account 
public class ContactTriggerHandler {
    public static void updateAccountRatings(List<Contact> newContacts, Map<Id, Contact> oldContactMap) {
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        Set<Id> accountIds = new Set<Id>();
        
        // Collect Account IDs
        for (Contact con : newContacts) {
            Contact oldCon = oldContactMap != null ? oldContactMap.get(con.Id) : null;
            if (con.AccountId != null && 
                (oldCon == null || con.level__c != oldCon.level__c || con.RecordTypeId != oldCon.RecordTypeId)) {
                accountIds.add(con.AccountId);
            }
        }
        System.debug('Account IDs to check: ' + accountIds);
        
        // Query for all related Contacts
        Map<Id, List<Contact>> accountToContacts = new Map<Id, List<Contact>>();
        for (Contact con : [SELECT Id, AccountId, RecordType.DeveloperName, level__c 
                            FROM Contact 
                            WHERE AccountId IN :accountIds]) {
            if (!accountToContacts.containsKey(con.AccountId)) {
                accountToContacts.put(con.AccountId, new List<Contact>());
            }
            accountToContacts.get(con.AccountId).add(con);
        }	
        System.debug('Accounts and their related Contacts: ' + accountToContacts);
        
        // Check conditions for each Account
        for (Id accountId : accountToContacts.keySet()) {
            boolean hasSecondaryInRT1 = false;
            boolean hasTertiaryInRT2 = false;
            
            for (Contact con : accountToContacts.get(accountId)) {
                System.debug('Checking Contact: ' + con);
                if (con.RecordType.DeveloperName == 'RT1' && con.level__c == 'Secondary') {
                    hasSecondaryInRT1 = true;
                    System.debug('Found Secondary in RT1');
                }
                if (con.RecordType.DeveloperName == 'RT2' && con.level__c == 'Tertiary') {
                    hasTertiaryInRT2 = true;
                    System.debug('Found Tertiary in RT2');
                }
            }
            
            // If both conditions are met, mark this Account for update
            if (hasSecondaryInRT1 && hasTertiaryInRT2) {
                accountsToUpdate.put(accountId, new Account(Id = accountId, Rating = 'Warm'));
                System.debug('Account ' + accountId + ' marked for update');
            } else {
                System.debug('Account ' + accountId + ' not marked for update. hasSecondaryInRT1: ' + hasSecondaryInRT1 + ', hasTertiaryInRT2: ' + hasTertiaryInRT2);
            }
        }
        
        // Update the Accounts
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate.values();
            System.debug('Updated Accounts: ' + accountsToUpdate.values());
        } else {
            System.debug('No Accounts to update');
        }
    }

}