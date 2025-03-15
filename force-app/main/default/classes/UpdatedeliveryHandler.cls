public class UpdatedeliveryHandler {	
    
    public static void processTasks(Map<Id, Task> newTaskMap, Map<Id, Task> oldTaskMap) {
            // Set = stocke les ID des opportunités 
    // Avantage : Optimisation des requêtes SOQL
    //  → On fait une seule requête pour récupérer toutes les tâches liées aux opportunités impactées.
        Set<Id> opportunityIds = new Set<Id>();

        // Ajouter les opportunités affectées par Insert, Update et Undelete
        if (newTaskMap != null) {
            for (Task t : newTaskMap.values()) {
                            // On vérifie que la tâche est bien liée à une Opportunité (WhatId pointe vers un Opportunity).

                if (t.WhatId != null && t.WhatId.getSObjectType() == Opportunity.SObjectType) {
                    opportunityIds.add(t.WhatId);
                }
            }
        }

        // Ajouter les opportunités affectées par Delete
        if (oldTaskMap != null) {
            for (Task t : oldTaskMap.values()) {
                if (t.WhatId != null && t.WhatId.getSObjectType() == Opportunity.SObjectType) {
                    opportunityIds.add(t.WhatId);
                }
            }
        }
    //  arrêter si aucune opportunité n’est trouvée ,quitte le trigger.

        if (opportunityIds.isEmpty()) return;

    // Récupération des tâches liées aux Opportunités concernées
    //  On regroupe les tâches par Opportunité dans une Map (oppTaskMap)
    //  Ici, la clé (Id) représente l’ID de l’opportunité.
	//   La valeur (List<Task>) contient la liste des tâches associées à cette opportunité. 
	       Map<Id, List<Task>> oppTaskMap = new Map<Id, List<Task>>();
        for (Task t : [SELECT Id, Status, WhatId FROM Task WHERE WhatId IN :opportunityIds]) {
            if (!oppTaskMap.containsKey(t.WhatId)) {
                oppTaskMap.put(t.WhatId, new List<Task>());
            }
            oppTaskMap.get(t.WhatId).add(t);
        }

    
   //  Préparation de la mise à jour des Opportunités
   //  On crée une liste opportunitiesToUpdate pour stocker les Opportunités à modifier.   
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();

        for (Id oppId : opportunityIds) {
            List<Task> tasks = oppTaskMap.get(oppId);
            Boolean hasOpenTasks = false;
        // check Task empty 

            if (tasks == null || tasks.isEmpty()) { 
                opportunitiesToUpdate.add(new Opportunity(Id = oppId, StageName = 'Needs Analysis'));
            } else {
                 // Check if any Task is NOT Completed
            // au moins 1 task completed 
                for (Task t : tasks) {
                    if (t.Status == 'Completed') {
                        hasOpenTasks = true;
                        break;
                    }
                }
                opportunitiesToUpdate.add(new Opportunity(Id = oppId, StageName = hasOpenTasks ? 'Closed Won' : 'Prospecting'));
            }
        }

        if (!opportunitiesToUpdate.isEmpty()) {
            update opportunitiesToUpdate;
        }
    }
}