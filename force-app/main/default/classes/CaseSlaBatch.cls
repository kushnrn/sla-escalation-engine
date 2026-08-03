public with sharing class CaseSlaBatch implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, CaseNumber, Priority, Status, Subject, CreatedDate
            FROM Case
            WHERE IsClosed = FALSE
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        CaseSlaEvaluationService.evaluateCases((List<Case>) scope);
    }

    public void finish(Database.BatchableContext bc) {}
}
