public with sharing class SlaErrorLogger {
    public static void logException(String source, Exception ex, List<Id> relatedIds) {
        if (ex == null) {
            return;
        }
        try {
            insert new SLA_Error_Log__c(
                Source__c = source,
                Message__c = ex.getMessage(),
                Stack_Trace__c = ex.getStackTraceString(),
                Related_Case_Id__c = relatedIds != null && !relatedIds.isEmpty() ? relatedIds[0] : null
            );
        } catch (DmlException dmlEx) {
            System.debug(LoggingLevel.ERROR, 'Unable to log SLA error: ' + dmlEx.getMessage());
        }
    }
}
