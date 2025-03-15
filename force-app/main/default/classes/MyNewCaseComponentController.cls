public class MyNewCaseComponentController {
    @AuraEnabled
    public static Case getParentCaseDetails(Id parentId) {
        return [SELECT Id, CaseNumber FROM Case WHERE Id = :parentId LIMIT 1];
    }

    @AuraEnabled
    public static Id saveCase(Case newCase) {
        insert newCase;
        return newCase.Id;
    }
}