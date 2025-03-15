@isTest
public class UpdatedeliveryTest {
    
    @testSetup
    static void setupData() {
        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(Name = 'Test op 1', StageName = 'Needs Analysis', CloseDate = Date.Today().addMonths(1)),
            new Opportunity(Name = 'Test op 2', StageName = 'Needs Analysis', CloseDate = Date.Today().addMonths(1))
        };
        insert opps;

        List<Task> tasks = new List<Task>{
            new Task(WhatId = opps[0].Id, Subject = 'Task1', Status = 'Not Started'),
            new Task(WhatId = opps[1].Id, Subject = 'Task2', Status = 'Not Started')
        };
        insert tasks;
    }

    @isTest
    static void testInsertTask() {
        Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        System.assertEquals('Needs Analysis', opp.StageName, 'Avant insertion, le StageName doit être Needs Analysis.');

        // Insertion d'une nouvelle tâche
        Task newTask = new Task(WhatId = opp.Id, Subject = 'New Task', Status = 'Completed');
        insert newTask;

        // Appel explicite du handler
        UpdatedeliveryHandler.processTasks(new Map<Id, Task>{newTask.Id => newTask}, null);

        // Vérification après l'insertion
        opp = [SELECT Id, StageName FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Closed Won', opp.StageName, 'Après insertion de tâche complétée, StageName doit être Closed Won.');
    }

    @isTest
    static void testUpdateTaskToCompleted() {
        Task t = [SELECT Id, WhatId, Status FROM Task LIMIT 1];
        t.Status = 'Completed';
        update t;

        // Appel explicite du handler
        UpdatedeliveryHandler.processTasks(new Map<Id, Task>{t.Id => t}, null);

        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Id = :t.WhatId];
        System.assertEquals('Closed Won', opp.StageName, 'Après mise à jour de tâche en "Completed", StageName doit être Closed Won.');
    }

    @isTest
    static void testDeleteTask() {
        Task t = [SELECT Id, WhatId FROM Task LIMIT 1];
        Id oppId = t.WhatId;
        delete t;

        // Appel explicite du handler
        UpdatedeliveryHandler.processTasks(null, new Map<Id, Task>{t.Id => t});

        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Id = :oppId];
        System.assertEquals('Needs Analysis', opp.StageName, 'Après suppression de la dernière tâche, StageName doit être Needs Analysis.');
    }
}