public with sharing class OpportunityCheckExtension {
    private final Opportunity opp;

    public OpportunityCheckExtension(ApexPages.StandardController stdController) {
        this.opp = (Opportunity)stdController.getRecord();
    }

    public Opportunity getOpportunity() {
        return opp;
        
    }
    
}