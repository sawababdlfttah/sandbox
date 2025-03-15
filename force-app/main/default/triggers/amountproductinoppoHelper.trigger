trigger amountproductinoppoHelper on OpportunityLineItem (after insert ,after update, after delete, after undelete ) {
    
// Ensemble pour stocker les IDs des Opportunités concernées
    Set<Id> opportunityIds = new Set<Id>();

    // Cas d'insert, update et undelete
    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        for (OpportunityLineItem oli : Trigger.new) {
            if (oli.OpportunityId != null) {
                opportunityIds.add(oli.OpportunityId);
            }
        }
    }

    // Cas de delete
    if (Trigger.isDelete) {
        for (OpportunityLineItem oli : Trigger.old) {
            if (oli.OpportunityId != null) {
                opportunityIds.add(oli.OpportunityId);
            }
        }
    }

    // Si aucune Opportunité concernée, arrêter l'exécution
    if (opportunityIds.isEmpty()) {
        return;
    }

    // Requête pour récupérer les sommes des montants des produits par Opportunité
    Map<Id, Decimal> opportunityAmountMap = new Map<Id, Decimal>();
    
    for (AggregateResult ar : [
    SELECT OpportunityId, SUM(TotalPrice) totalAmounttt
    FROM OpportunityLineItem
    WHERE OpportunityId IN :opportunityIds
    GROUP BY OpportunityId
]) {
    Decimal total = (Decimal) ar.get('totalAmounttt');
    System.debug('Total Amount for Opportunity ' + ar.get('OpportunityId') + ': ' + total);
    opportunityAmountMap.put((Id) ar.get('OpportunityId'), total);
    System.debug('Total Amount Map (decimal format) : ' + JSON.serializePretty(opportunityAmountMap));

}


    // Liste des Opportunités à mettre à jour
    List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();

    for (Id oppId : opportunityIds) {
        Opportunity opp = new Opportunity(Id = oppId);
        opp.Total_Amount_Product__c = opportunityAmountMap.containsKey(oppId) ? opportunityAmountMap.get(oppId) : 0;
        opportunitiesToUpdate.add(opp);
    }

    // Mise à jour des Opportunités
    if (!opportunitiesToUpdate.isEmpty()) {
        update opportunitiesToUpdate;
    }
}