public with sharing class CaseSlaEvaluationQueueable implements Queueable {
    private List<Id> caseIds;
    private Integer retryCount;

    public CaseSlaEvaluationQueueable(List<Id> caseIds) {
        this(caseIds, 0);
    }

    public CaseSlaEvaluationQueueable(List<Id> caseIds, Integer retryCount) {
        this.caseIds = caseIds;
        this.retryCount = retryCount;
    }

    public void execute(QueueableContext context) {
        try {
            CaseSlaEvaluationService.evaluateCases(caseIds);
        } catch (Exception ex) {
            SlaErrorLogger.logException('CaseSlaEvaluationQueueable', ex, caseIds);
            if (retryCount < 1) {
                System.enqueueJob(new CaseSlaEvaluationQueueable(caseIds, retryCount + 1));
            }
        }
    }
}
