trigger CaseTrigger on Case (after insert, after update) {
    TriggerHandler handler = new CaseSlaTriggerHandler();
    if (Trigger.isAfter && Trigger.isInsert) {
        handler.afterInsert(Trigger.new, Trigger.newMap);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        handler.afterUpdate(Trigger.oldMap, Trigger.newMap);
    }
}
