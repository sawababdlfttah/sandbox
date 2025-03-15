public with sharing class OpportunityController {
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunitiesByRecordType(String recordTypeName, Date selectedDate) {
        System.debug('getOpportunitiesByRecordType called with recordTypeName: ' + recordTypeName + ' and selectedDate: ' + selectedDate);
        
        String query = 'SELECT Id, Name, RecordType.Name, CloseDate, Amount FROM Opportunity WHERE CloseDate > =:selectedDate';
        
        if (String.isNotBlank(recordTypeName)) {
            query += ' AND RecordType.Name = :recordTypeName';
        }
        
        if (selectedDate != null) {
            query += ' AND CloseDate >= :selectedDate';
        }
        
        query += ' ORDER BY CloseDate ASC LIMIT 1000';
        
        System.debug('Executing query: ' + query);
        List<Opportunity> opportunities = Database.query(query);
        System.debug('Returned ' + opportunities.size() + ' opportunities');
        
        // Add detailed logging for each opportunity
        for (Opportunity opp : opportunities) {
            System.debug('Opportunity: Id=' + opp.Id + ', Name=' + opp.Name + 
                         ', RecordType=' + opp.RecordType.Name + 
                         ', CloseDate=' + opp.CloseDate);
        }
        
        // If no opportunities found, log some sample data
        if (opportunities.isEmpty()) {
            System.debug('No opportunities found. Checking for sample data...');
            List<Opportunity> sampleData = [SELECT Id, Name, RecordType.Name, CloseDate, Amount 
                                            FROM Opportunity 
                                            WHERE RecordType.Name = :recordTypeName 
                                            LIMIT 5];
            for (Opportunity opp : sampleData) {
                System.debug('Sample Opportunity: Id=' + opp.Id + ', Name=' + opp.Name + 
                             ', RecordType=' + opp.RecordType.Name + 
                             ', CloseDate=' + opp.CloseDate);
            }
        }
        
        return opportunities;
    

}
    @AuraEnabled(cacheable=true)
    public static List<RecordType> getOpportunityRecordTypes() {
        System.debug('getOpportunityRecordTypes called');
        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Opportunity'];
        System.debug('Returned ' + recordTypes.size() + ' record types');
        return recordTypes;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getOpportunityNameSuggestions(String searchTerm, String recordTypeName) {
        System.debug('getOpportunityNameSuggestions called with searchTerm: ' + searchTerm + ' and recordTypeName: ' + recordTypeName);
        
        String likeSearchTerm = '%' + searchTerm + '%';
        String query = 'SELECT Name FROM Opportunity WHERE Name LIKE :likeSearchTerm';
        
        if (String.isNotBlank(recordTypeName)) {
            query += ' AND RecordType.Name = :recordTypeName';
        }
        
        query += ' LIMIT 5';
        
        System.debug('Executing query: ' + query);
        List<Opportunity> opportunities = Database.query(query);
        
        List<String> suggestions = new List<String>();
        for (Opportunity opp : opportunities) {
            suggestions.add(opp.Name);
        }
        
        System.debug('Returned ' + suggestions.size() + ' name suggestions');
        return suggestions;
    }
}