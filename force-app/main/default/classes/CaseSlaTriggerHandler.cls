public with sharing class CaseSlaTriggerHandler extends TriggerHandler {
    public override void afterInsert(List<SObject> newRecords, Map<Id, SObject> newMap) {
        List<Id> caseIds = new List<Id>();
        for (SObject record : newRecords) {
            caseIds.add(record.Id);
        }
        if (!caseIds.isEmpty()) {
            System.enqueueJob(new CaseSlaEvaluationQueueable(caseIds));
        }
    }

    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        List<Id> caseIds = new List<Id>();
        for (Id recordId : newMap.keySet()) {
            Case oldCase = (Case) oldMap.get(recordId);
            Case newCase = (Case) newMap.get(recordId);
            if (oldCase.Status != newCase.Status || oldCase.Priority != newCase.Priority || oldCase.OwnerId != newCase.OwnerId) {
                caseIds.add(recordId);
            }
        }
        if (!caseIds.isEmpty()) {
            System.enqueueJob(new CaseSlaEvaluationQueueable(caseIds));
        }
    }
}
