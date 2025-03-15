trigger CandidatureTrigger on Candidature__c (before insert, after insert) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            CandidatureTriggerHandler.handleBeforeInsert(Trigger.new);
        }
    }
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            CandidatureTriggerHandler.handleAfterInsert(Trigger.new);
        }
    }
}