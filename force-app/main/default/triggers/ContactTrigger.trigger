trigger ContactTrigger on Contact (after insert, after update) {
  //  if (Trigger.isAfter) {
    ContactTriggerHandler.updateAccountRatings(Trigger.new, Trigger.oldMap);
   // }
}