trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
    AccountTriggerHandler.handleTrigger(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, Trigger.isInsert, Trigger.isUpdate);
}