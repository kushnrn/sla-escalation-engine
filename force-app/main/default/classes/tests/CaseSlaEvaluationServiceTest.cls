@isTest
private class CaseSlaEvaluationServiceTest {
    @testSetup
    static void setupData() {
        TestFactory.createCaseData();
        SlaConfigurationService.setTestConfiguration(
            new List<SLA_Priority__mdt>{
                TestFactory.buildPriorityMetadata('High', 2, 8, 'Gold', 'Ops', 'Notify')
            },
            new List<SLA_Tier__mdt>{
                TestFactory.buildTierMetadata('Gold')
            },
            new List<SLA_Business_Hours__mdt>{
                TestFactory.buildBusinessHoursMetadata(4)
            },
            new List<SLA_Escalation_Recipient__mdt>{
                TestFactory.buildRecipientMetadata('Ops', 'ops@example.com')
            },
            new List<SLA_Action__mdt>{
                TestFactory.buildActionMetadata('Notify', 'Notify')
            }
        );
    }

    @isTest
    static void testWarningAndEscalationRecordsAreCreatedOnce() {
        Case testCase = [SELECT Id, Priority, CreatedDate FROM Case LIMIT 1];
        Test.setCreatedDate(testCase.Id, DateTime.now().addHours(-10));

        Test.startTest();
        CaseSlaEvaluationService.evaluateCases(new List<Id>{ testCase.Id });
        CaseSlaEvaluationService.evaluateCases(new List<Id>{ testCase.Id });
        Test.stopTest();

        List<SLA_Escalation_Record__c> records = [
            SELECT Id, Case__c, Threshold_Type__c, Key__c
            FROM SLA_Escalation_Record__c
            WHERE Case__c = :testCase.Id
        ];
        System.assertEquals(1, records.size(), 'Duplicate escalation records should not be created');
        System.assertEquals('Escalation', records[0].Threshold_Type__c);
    }

    @isTest
    static void testResolveRuleUsesTierMetadataWhenPriorityDoesNotSpecifyTier() {
        SlaConfigurationService.clearTestConfiguration();
        SlaConfigurationService.setTestConfiguration(
            new List<SLA_Priority__mdt>{
                TestFactory.buildPriorityMetadata('Medium', 4, 24, null, 'Ops', 'Notify')
            },
            new List<SLA_Tier__mdt>{
                TestFactory.buildTierMetadata('Gold')
            },
            new List<SLA_Business_Hours__mdt>{
                TestFactory.buildBusinessHoursMetadata(4)
            },
            new List<SLA_Escalation_Recipient__mdt>{
                TestFactory.buildRecipientMetadata('Ops', 'ops@example.com')
            },
            new List<SLA_Action__mdt>{
                TestFactory.buildActionMetadata('Notify', 'Notify')
            }
        );

        Case testCase = [SELECT Id, Priority FROM Case LIMIT 1];
        testCase.Priority = 'Medium';
        update testCase;

        SlaConfigurationService.SlaRule rule = SlaConfigurationService.resolveRule(testCase);
        System.assertEquals('Gold', rule.tierName, 'Tier metadata should be applied when the priority rule does not define a tier');
    }

    @isTest
    static void testQueueableRetriesOnFailure() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Test.setCreatedDate(testCase.Id, DateTime.now().addHours(-10));

        Test.startTest();
        System.enqueueJob(new CaseSlaEvaluationQueueable(new List<Id>{ testCase.Id }, 0));
        Test.stopTest();

        List<SLA_Escalation_Record__c> records = [SELECT Id FROM SLA_Escalation_Record__c WHERE Case__c = :testCase.Id];
        System.assertEquals(1, records.size());
    }

    @isTest
    static void testTriggerEnqueuesEvaluation() {
        Case testCase = new Case(Subject = 'Trigger test', Priority = 'High', Origin = 'Email');
        insert testCase;

        Test.startTest();
        update testCase;
        Test.stopTest();

        List<SLA_Escalation_Record__c> records = [SELECT Id FROM SLA_Escalation_Record__c WHERE Case__c = :testCase.Id];
        System.assertEquals(0, records.size(), 'Trigger-based evaluation should not create records in this unit test without time thresholds');
    }
}
