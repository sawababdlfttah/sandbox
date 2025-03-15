global class UpdateAccountSLABatch implements Database.Batchable<sObject>, Database.Stateful {
    
    private List<Id> newOpportunityIds = new List<Id>();
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('Starting UpdateAccountSLABatch');
        return Database.getQueryLocator([
            SELECT Id, (SELECT Id, StageName, RecordTypeId FROM Opportunities)
            FROM Account
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        System.debug('Executing batch for ' + scope.size() + ' accounts');
        List<Account> accountsToUpdate = new List<Account>();
        List<Opportunity> newOpportunities = new List<Opportunity>();
        
        Id rt1Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('RT1').getRecordTypeId();
        Id rt2Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('RT2').getRecordTypeId();
        
        System.debug('RT1 Id: ' + rt1Id + ', RT2 Id: ' + rt2Id);
        
        for (Account acc : scope) {
            boolean hasRT1Prospecting = false;
            boolean hasRT2PerceptionAnalysis = false;
            
            System.debug('Processing Account: ' + acc.Id + ' with ' + acc.Opportunities.size() + ' opportunities');
            
            for (Opportunity opp : acc.Opportunities) {
                if (opp.RecordTypeId == rt1Id && opp.StageName == 'Prospecting') {
                    hasRT1Prospecting = true;
                    System.debug('Found RT1 Prospecting opportunity: ' + opp.Id);
                } else if (opp.RecordTypeId == rt2Id && opp.StageName == 'Perception Analysis') {
                    hasRT2PerceptionAnalysis = true;
                    System.debug('Found RT2 Perception Analysis opportunity: ' + opp.Id);
                }
                
                if (hasRT1Prospecting && hasRT2PerceptionAnalysis) {
	                    break;
                }
            }
            
            if (hasRT1Prospecting && hasRT2PerceptionAnalysis) {
                acc.SLA__c = 'Gold';
                accountsToUpdate.add(acc);
                System.debug('Account ' + acc.Id + ' qualifies for Gold SLA');
                
                // Create new RT2 Opportunity
                Opportunity newOpp = new Opportunity(
                    Name = 'New RT2 Opportunity for ' + acc.Id,
                    AccountId = acc.Id,
                    StageName = 'Prospecting',
                    CloseDate = Date.today().addDays(30),
                    RecordTypeId = rt2Id
                );
                newOpportunities.add(newOpp);
            } else {
                System.debug('Account ' + acc.Id + ' does not qualify for Gold SLA');
            }
        }
        
        if (!accountsToUpdate.isEmpty()) {
            System.debug('Updating ' + accountsToUpdate.size() + ' accounts');
            update accountsToUpdate;
        } else {
            System.debug('No accounts to update');
        }
        
        if (!newOpportunities.isEmpty()) {
            insert newOpportunities;
            newOpportunityIds.addAll(new Map<Id, Opportunity>(newOpportunities).keySet());
            System.debug('Created ' + newOpportunities.size() + ' new opportunities');
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        System.debug('Finished UpdateAccountSLABatch');
        
        if (!newOpportunityIds.isEmpty()) {
            // Create a custom notification
            CustomNotificationType notificationType = [SELECT Id, DeveloperName 
                                                       FROM CustomNotificationType 
                                                       WHERE DeveloperName = 'New_RT2_Opportunity_Notification' 
                                                       LIMIT 1];
            
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('New RT2 Opportunities Created');
            notification.setBody('New RT2 Opportunities have been created for accounts that met the Gold SLA criteria.');
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(newOpportunityIds[0]); 
            
            // Send notification to all users
            Set<String> recipientIds = new Set<String>();
            for (User u : [SELECT Id FROM User WHERE IsActive = true]) {
                recipientIds.add(u.Id);
            }
            
            notification.send(recipientIds);
            
            // Prepare navigation information
            String navigationInfo = 'Lightning Component: c:viewNewOpportunities\n';
            navigationInfo += 'Attributes: {\n';
            navigationInfo += '    opportunityIds: ' + JSON.serialize(newOpportunityIds) + '\n';
            navigationInfo += '}';
            
            System.debug('Navigation Information for new Opportunities:\n' + navigationInfo);
        } else {
            System.debug('No new opportunities were created');
        }
    }
}