@isTest
public class TestFactory {
    public static void createCaseData() {
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 3; i++) {
            cases.add(new Case(
                Subject = 'SLA Test ' + i,
                Priority = i == 0 ? 'High' : 'Medium',
                Origin = 'Email',
                Status = 'New'
            ));
        }
        insert cases;
    }

    public static SLA_Priority__mdt buildPriorityMetadata(String name, Decimal warningHours, Decimal escalationHours, String tierName, String recipientName, String actionName) {
        SLA_Priority__mdt rule = new SLA_Priority__mdt();
        rule.Priority_Name__c = name;
        rule.Warning_Hours__c = warningHours;
        rule.Escalation_Hours__c = escalationHours;
        rule.Tier_Name__c = tierName;
        rule.Recipient_Name__c = recipientName;
        rule.Action_Name__c = actionName;
        rule.Is_Active__c = true;
        return rule;
    }

    public static SLA_Tier__mdt buildTierMetadata(String tierName) {
        SLA_Tier__mdt tier = new SLA_Tier__mdt();
        tier.Tier_Name__c = tierName;
        tier.Is_Active__c = true;
        return tier;
    }

    public static SLA_Business_Hours__mdt buildBusinessHoursMetadata(Decimal thresholdHours) {
        SLA_Business_Hours__mdt businessHours = new SLA_Business_Hours__mdt();
        businessHours.Threshold_Hours__c = thresholdHours;
        businessHours.Is_Active__c = true;
        return businessHours;
    }

    public static SLA_Escalation_Recipient__mdt buildRecipientMetadata(String name, String email) {
        SLA_Escalation_Recipient__mdt recipient = new SLA_Escalation_Recipient__mdt();
        recipient.Recipient_Name__c = name;
        recipient.Email__c = email;
        recipient.Is_Active__c = true;
        return recipient;
    }

    public static SLA_Action__mdt buildActionMetadata(String name, String actionType) {
        SLA_Action__mdt action = new SLA_Action__mdt();
        action.Action_Name__c = name;
        action.Action_Type__c = actionType;
        action.Is_Active__c = true;
        return action;
    }
}
