trigger CaseTrigger on Case (after insert, after update, after delete) {
    // Store Account IDs
    Set<Id> accountIds = new Set<Id>();

    if (Trigger.isInsert || Trigger.isUpdate) {
        for (Case c : Trigger.new) {
            if (c.AccountId != null) {
                accountIds.add(c.AccountId);
            }
        }
    }

    if (Trigger.isDelete) {
        for (Case c : Trigger.old) {
            if (c.AccountId != null) {
                accountIds.add(c.AccountId);
            }
        }
    }

    // Fetch Accounts
    Map<Id, Account> accountMap = new Map<Id, Account>(
        [SELECT Id, TotalCaseOpen__c, TotalClosedCase__c FROM Account WHERE Id IN :accountIds]
    );

    // Maps to track counts
    Map<Id, Integer> accountOpenCaseCount = new Map<Id, Integer>();
    Map<Id, Integer> accountClosedCaseCount = new Map<Id, Integer>();

    // Fetch all related cases
    List<Case> relatedCases = [SELECT Id, AccountId, Status FROM Case WHERE AccountId IN :accountIds];

    for (Case c : relatedCases) {
        // Count open cases (Status = 'New')
        if (c.Status == 'New') {
            if (accountOpenCaseCount.containsKey(c.AccountId)) {
                accountOpenCaseCount.put(c.AccountId, accountOpenCaseCount.get(c.AccountId) + 1);
            } else {
                accountOpenCaseCount.put(c.AccountId, 1);
            }
        }

        // Count closed cases (Status = 'Escalated' OR 'Closed')
        if (c.Status == 'Closed' || c.Status == 'Escalated') {
            if (accountClosedCaseCount.containsKey(c.AccountId)) {
                accountClosedCaseCount.put(c.AccountId, accountClosedCaseCount.get(c.AccountId) + 1);
            } else {
                accountClosedCaseCount.put(c.AccountId, 1);
            }
        }
    }

    // List to hold accounts for update
    List<Account> accountsToUpdate = new List<Account>();

    for (Id accountId : accountMap.keySet()) {
        Account acct = accountMap.get(accountId);

        // Update TotalCaseOpen__c
        acct.TotalCaseOpen__c = accountOpenCaseCount.containsKey(accountId) ? accountOpenCaseCount.get(accountId) : 0;

        // Update TotalClosedCase__c
        acct.TotalClosedCase__c = accountClosedCaseCount.containsKey(accountId) ? accountClosedCaseCount.get(accountId) : 0;

        accountsToUpdate.add(acct);
    }

    // Perform DML update
    if (!accountsToUpdate.isEmpty()) {
        update accountsToUpdate;
    }
}