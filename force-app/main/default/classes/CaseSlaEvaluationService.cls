public with sharing class CaseSlaEvaluationService {
    public static void evaluateCases(List<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) {
            return;
        }

        List<Case> cases = [
            SELECT Id, CaseNumber, Priority, Status, Subject, CreatedDate
            FROM Case
            WHERE Id IN :caseIds AND IsClosed = FALSE
        ];
        evaluateCases(cases);
    }

    public static void evaluateCases(List<Case> cases) {
        if (cases == null || cases.isEmpty()) {
            return;
        }

        List<Case> readableCases = cases;
        try {
            readableCases = (List<Case>) Security.stripInaccessible(AccessType.READABLE, cases).getRecords();
        } catch (Exception ex) {
            SlaErrorLogger.logException('CaseSlaEvaluationService', ex, new List<Id>());
            return;
        }

        if (readableCases.isEmpty()) {
            return;
        }

        List<SLA_Escalation_Record__c> escalationRecords = new List<SLA_Escalation_Record__c>();
        List<SLA_Breach_Event__e> eventsToPublish = new List<SLA_Breach_Event__e>();
        Set<String> requestedKeys = new Set<String>();

        for (Case currentCase : readableCases) {
            SlaConfigurationService.SlaRule rule = SlaConfigurationService.resolveRule(currentCase);
            Decimal hoursOpen = calculateHoursOpen(currentCase);

            if (hoursOpen >= rule.escalationHours) {
                requestedKeys.add(buildKey(currentCase.Id, 'Escalation'));
                escalationRecords.add(buildEscalationRecord(currentCase, rule, 'Escalation'));
                eventsToPublish.add(buildPlatformEvent(currentCase, rule, 'Escalation'));
            } else if (hoursOpen >= rule.warningHours) {
                requestedKeys.add(buildKey(currentCase.Id, 'Warning'));
                escalationRecords.add(buildEscalationRecord(currentCase, rule, 'Warning'));
                eventsToPublish.add(buildPlatformEvent(currentCase, rule, 'Warning'));
            }
        }

        if (escalationRecords.isEmpty()) {
            return;
        }

        Map<String, SLA_Escalation_Record__c> existingRecordsByKey = new Map<String, SLA_Escalation_Record__c>();
        for (SLA_Escalation_Record__c existingRecord : [
            SELECT Id, Key__c
            FROM SLA_Escalation_Record__c
            WHERE Key__c IN :requestedKeys
        ]) {
            existingRecordsByKey.put(existingRecord.Key__c, existingRecord);
        }

        List<SLA_Escalation_Record__c> recordsToInsert = new List<SLA_Escalation_Record__c>();
        List<SLA_Breach_Event__e> eventsToEmit = new List<SLA_Breach_Event__e>();

        for (Integer i = 0; i < escalationRecords.size(); i++) {
            SLA_Escalation_Record__c record = escalationRecords[i];
            if (!existingRecordsByKey.containsKey(record.Key__c)) {
                recordsToInsert.add(record);
                eventsToEmit.add(eventsToPublish[i]);
            }
        }

        if (!recordsToInsert.isEmpty()) {
            try {
                Database.SaveResult[] result = Database.insert(recordsToInsert, false);
                for (Integer i = 0; i < result.size(); i++) {
                    if (result[i].isSuccess()) {
                        EventBus.publish(eventsToEmit[i]);
                    }
                }
            } catch (Exception ex) {
                SlaErrorLogger.logException('CaseSlaEvaluationService', ex, new List<Id>{});
            }
        }
    }

    private static Decimal calculateHoursOpen(Case currentCase) {
        if (currentCase.CreatedDate == null) {
            return 0;
        }
        Long elapsedMs = System.now().getTime() - currentCase.CreatedDate.getTime();
        return Decimal.valueOf(elapsedMs) / Decimal.valueOf(3600000);
    }

    private static SLA_Escalation_Record__c buildEscalationRecord(Case currentCase, SlaConfigurationService.SlaRule rule, String thresholdType) {
        return new SLA_Escalation_Record__c(
            Case__c = currentCase.Id,
            Threshold_Type__c = thresholdType,
            Threshold_Hours__c = thresholdType == 'Escalation' ? rule.escalationHours : rule.warningHours,
            Recipient_Email__c = rule.recipientEmail,
            Action_Name__c = rule.actionName,
            Tier_Name__c = rule.tierName,
            Key__c = buildKey(currentCase.Id, thresholdType)
        );
    }

    private static SLA_Breach_Event__e buildPlatformEvent(Case currentCase, SlaConfigurationService.SlaRule rule, String thresholdType) {
        return new SLA_Breach_Event__e(
            Case_Id__c = currentCase.Id,
            Event_Type__c = thresholdType,
            Threshold_Hours__c = thresholdType == 'Escalation' ? rule.escalationHours : rule.warningHours,
            Message__c = thresholdType + ' threshold reached for case ' + currentCase.CaseNumber,
            Recipient_Email__c = rule.recipientEmail
        );
    }

    private static String buildKey(Id caseId, String thresholdType) {
        return caseId + ':' + thresholdType;
    }
}
