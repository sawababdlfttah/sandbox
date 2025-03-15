public class UpdateRevenueBySectorBatch implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Récupérer tous les comptes
        return Database.getQueryLocator('SELECT Id, Secteur__c FROM Account WHERE Secteur__c != null');
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        // Étape 1 : Récupérer les secteurs d'activité des comptes
        Set<String> secteurs = new Set<String>();
        for (Account acc : scope) {
            secteurs.add(acc.Secteur__c);
        }

        // Étape 2 : Calculer le chiffre d'affaires total par secteur
        Map<String, Decimal> revenueBySector = new Map<String, Decimal>();
        for (AggregateResult ar : [
            SELECT Account.Secteur__c secteur, SUM(Amount) totalRevenue
            FROM Opportunity
            WHERE Account.Secteur__c IN :secteurs AND StageName = 'Closed Won'
            GROUP BY Account.Secteur__c
        ]) {
            String secteur = (String) ar.get('secteur');
            Decimal totalRevenue = (Decimal) ar.get('totalRevenue');
            revenueBySector.put(secteur, totalRevenue);
        }

        // Étape 3 : Mettre à jour les comptes avec le chiffre d'affaires de leur secteur
        List<Account> accountsToUpdate = new List<Account>();
        for (Account acc : scope) {
            if (revenueBySector.containsKey(acc.Secteur__c)) {
                acc.Chiffre_d_affaires_par_secteur__c = revenueBySector.get(acc.Secteur__c);
                accountsToUpdate.add(acc);
            }
        }

        // Mettre à jour les comptes
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Mise à jour du chiffre d\'affaires par secteur terminée !');
    }
}