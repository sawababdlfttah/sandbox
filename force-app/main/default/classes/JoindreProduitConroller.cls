public with sharing class JoindreProduitConroller {
    @AuraEnabled
    public static void setLink(Id recordId, String fileURL) {
        try {
            Contact contact = [SELECT Id, URL__c FROM Contact WHERE Id = :recordId];
            Contact.URL__c = fileURL;
            update contact;
            System.debug('Updated produit: ' + contact);
        } catch (Exception ex) {
            System.debug('Error joindre contrat controller: ' + ex.getMessage());
        }
    }
}