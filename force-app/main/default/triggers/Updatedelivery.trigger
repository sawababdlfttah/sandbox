trigger Updatedelivery on Task (before insert, after update, after delete, after undelete) {
    if (Trigger.isBefore && Trigger.isInsert) {
        UpdatedeliveryHandler.processTasks(Trigger.newMap, null);
    }

    if (Trigger.isAfter && (Trigger.isUpdate || Trigger.isDelete || Trigger.isUndelete)) {
        UpdatedeliveryHandler.processTasks(Trigger.newMap, Trigger.oldMap);
    }
}