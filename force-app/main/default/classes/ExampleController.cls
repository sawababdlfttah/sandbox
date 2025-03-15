public class ExampleController {
    @AuraEnabled
    public static String getUserNum(Id userId) {
        User selectedUser = [SELECT Num__c FROM User WHERE Id = :userId LIMIT 1];
        return selectedUser.Num__c;
    }
}