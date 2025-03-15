public with sharing class OpportunityLineItemController {
    private final Opportunity opportunity;
    public List<OpportunityLineItem> lineItems { get; set; }

    public OpportunityLineItemController(ApexPages.StandardController stdController) {
        this.opportunity = (Opportunity) stdController.getRecord();
        this.lineItems = [SELECT Id, Product2.Name, Quantity, UnitPrice, TotalPrice,OpportunityId, Opportunity.Name
                          FROM OpportunityLineItem    ];
    }
}