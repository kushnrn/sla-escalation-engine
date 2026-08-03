# Entitlement & SLA Escalation Engine

A Salesforce DX project that demonstrates a metadata-driven SLA and escalation engine for Case management. This implementation is designed to highlight senior-level patterns such as asynchronous Apex, bulk processing, metadata-driven configuration, security-aware service design, idempotency, and testability.

## Why this project matters
This solution models a realistic support operations scenario where open Cases must be evaluated against configurable SLA thresholds. Instead of hardcoding rules into Apex, the engine reads them from Custom Metadata Types so business teams can adjust policies without changing code.

## What is included
- Apex service logic for evaluating open Cases against SLA rules
- Custom Metadata Types for priority, tier, business-hours threshold, recipient, and action configuration
- Queueable Apex for asynchronous evaluation on trigger-driven updates
- Batch Apex for bulk processing of large Case volumes
- Platform Events for warning and escalation threshold breaches
- Trigger-handler orchestration with a service-based structure
- Security-aware querying using `with sharing`
- Error logging and retry-safe, idempotent escalation record creation
- Apex test data factory and unit tests

## Architecture at a glance
The engine follows a layered design:

1. Trigger entry point
   - Case insert/update events enter the trigger flow.
2. Handler layer
   - The trigger handler decides whether to enqueue asynchronous evaluation.
3. Evaluation service
   - The service evaluates open Cases against the configured SLA rules.
4. Configuration layer
   - SLA thresholds, recipients, and actions are resolved from Custom Metadata Types.
5. Persistence and eventing
   - Escalation records are stored, and Platform Events are published for downstream processing.

## Key technical highlights
- Metadata-driven design
  - SLA behavior is configurable without code changes.
- Async processing
  - Queueable Apex handles trigger-driven execution efficiently.
- Bulkification
  - Batch Apex supports large-volume processing.
- Idempotency
  - Escalation records use a composite key so repeat runs do not create duplicates.
- Reliability
  - Error logging captures unexpected failures for monitoring and debugging.
- Testability
  - The solution includes Apex test factories and regression-style tests.

## Main project files
- [force-app/main/default/classes/CaseSlaEvaluationService.cls](force-app/main/default/classes/CaseSlaEvaluationService.cls)
- [force-app/main/default/classes/CaseSlaEvaluationQueueable.cls](force-app/main/default/classes/CaseSlaEvaluationQueueable.cls)
- [force-app/main/default/classes/CaseSlaBatch.cls](force-app/main/default/classes/CaseSlaBatch.cls)
- [force-app/main/default/classes/SlaConfigurationService.cls](force-app/main/default/classes/SlaConfigurationService.cls)
- [force-app/main/default/triggers/CaseTrigger.trigger](force-app/main/default/triggers/CaseTrigger.trigger)
- [force-app/main/default/objects/SLA_Escalation_Record__c](force-app/main/default/objects/SLA_Escalation_Record__c)
- [force-app/main/default/objects/SLA_Breach_Event__e](force-app/main/default/objects/SLA_Breach_Event__e)
- [force-app/main/default/classes/tests/CaseSlaEvaluationServiceTest.cls](force-app/main/default/classes/tests/CaseSlaEvaluationServiceTest.cls)

## How to run it
### 1. Create or select a scratch org
```bash
sfdx force:org:create -f config/project-scratch-def.json -a sla-demo
```

### 2. Push source to the org
```bash
sfdx force:source:push -u sla-demo
```

### 3. Create a test Case
```apex
Case c = new Case(
    Subject = 'SLA engine smoke test',
    Priority = 'High',
    Origin = 'Email',
    Status = 'New'
);
insert c;


### 4. Trigger the evaluation
```apex
Database.executeBatch(new CaseSlaBatch(), 50);
```

Or asynchronously:
```apex
Id caseId = [SELECT Id FROM Case WHERE Subject = 'SLA engine smoke test' LIMIT 1].Id;
System.enqueueJob(new CaseSlaEvaluationQueueable(new List<Id>{ caseId }));
```

### 5. Verify the results
```apex
SELECT Id, Case__c, Threshold_Type__c, Threshold_Hours__c
FROM SLA_Escalation_Record__c;
```

## Testing approach
The project includes Apex tests that cover:
- idempotent escalation creation
- queueable execution behavior
- trigger-driven evaluation paths
