public with sharing class AccountContactController {
    @AuraEnabled(cacheable=true)
    public static List<RecordTypeInfo> getAccountRecordTypes() {
        List<RecordTypeInfo> recordTypes = new List<RecordTypeInfo>();
        for (Schema.RecordTypeInfo rt : Schema.SObjectType.Account.getRecordTypeInfos()) {
            if(rt.isAvailable() && !rt.isMaster()) {
                recordTypes.add(new RecordTypeInfo(rt.getRecordTypeId(), rt.getName(), rt.getDeveloperName()));
            }
        }
        return recordTypes;
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getAccountsByRecordType(String recordTypeId) {
        return [SELECT Id, Name FROM Account WHERE RecordTypeId = :recordTypeId LIMIT 100];
    }

    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactsByAccount(String accountId) {
        return [SELECT Id, FirstName, LastName, Email, Phone FROM Contact WHERE AccountId = :accountId];
    }

    @AuraEnabled
    public static void updateContactPhone(List<Contact> contactUpdates) {
        try {
            update contactUpdates;
        } catch (DmlException e) {
            throw new AuraHandledException('Error updating contacts: ' + e.getMessage());
        }
    }

    public class RecordTypeInfo {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String developerName;

        public RecordTypeInfo(String id, String name, String developerName) {
            this.id = id;
            this.name = name;
            this.developerName = developerName;
        }
    }
    
}