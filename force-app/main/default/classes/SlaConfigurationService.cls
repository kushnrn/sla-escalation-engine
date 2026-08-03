public with sharing class SlaConfigurationService {
    @TestVisible
    private static List<SLA_Priority__mdt> priorityRuleOverrides;
    @TestVisible
    private static List<SLA_Tier__mdt> tierRuleOverrides;
    @TestVisible
    private static List<SLA_Business_Hours__mdt> businessHoursOverrides;
    @TestVisible
    private static List<SLA_Escalation_Recipient__mdt> recipientOverrides;
    @TestVisible
    private static List<SLA_Action__mdt> actionOverrides;

    public class SlaRule {
        public String tierName;
        public Decimal warningHours = 4;
        public Decimal escalationHours = 24;
        public String recipientEmail = 'ops@example.com';
        public String actionName = 'Notify';
    }

    public static SlaRule resolveRule(Case currentCase) {
        SlaRule rule = new SlaRule();
        String priorityName = String.isBlank(currentCase.Priority) ? 'Medium' : currentCase.Priority.trim();
        Boolean prioritySpecifiedTier = false;

        for (SLA_Priority__mdt priorityRule : getPriorityRules()) {
            if (priorityRule.Is_Active__c != true) {
                continue;
            }
            if (priorityRule.Priority_Name__c != null && priorityRule.Priority_Name__c.trim().equalsIgnoreCase(priorityName)) {
                if (priorityRule.Warning_Hours__c != null) {
                    rule.warningHours = priorityRule.Warning_Hours__c;
                }
                if (priorityRule.Escalation_Hours__c != null) {
                    rule.escalationHours = priorityRule.Escalation_Hours__c;
                }
                if (String.isNotBlank(priorityRule.Tier_Name__c)) {
                    rule.tierName = priorityRule.Tier_Name__c;
                    prioritySpecifiedTier = true;
                }
                if (String.isNotBlank(priorityRule.Recipient_Name__c)) {
                    SLA_Escalation_Recipient__mdt recipient = getRecipientByName(priorityRule.Recipient_Name__c);
                    if (recipient != null && String.isNotBlank(recipient.Email__c)) {
                        rule.recipientEmail = recipient.Email__c;
                    }
                }
                if (String.isNotBlank(priorityRule.Action_Name__c)) {
                    SLA_Action__mdt action = getActionByName(priorityRule.Action_Name__c);
                    if (action != null && String.isNotBlank(action.Action_Type__c)) {
                        rule.actionName = action.Action_Type__c;
                    }
                }
                break;
            }
        }

        if (rule.warningHours == null || rule.warningHours <= 0) {
            rule.warningHours = 4;
        }
        if (rule.escalationHours == null || rule.escalationHours <= 0) {
            rule.escalationHours = 24;
        }

        if (!prioritySpecifiedTier) {
            applyTierMetadata(rule);
        }

        for (SLA_Business_Hours__mdt businessHours : getBusinessHoursRules()) {
            if (businessHours.Is_Active__c == true && businessHours.Threshold_Hours__c != null) {
                rule.warningHours = businessHours.Threshold_Hours__c;
                rule.escalationHours = Math.max(rule.escalationHours, businessHours.Threshold_Hours__c * 2);
                break;
            }
        }

        return rule;
    }

    public static void setTestConfiguration(
        List<SLA_Priority__mdt> priorities,
        List<SLA_Tier__mdt> tiers,
        List<SLA_Business_Hours__mdt> businessHours,
        List<SLA_Escalation_Recipient__mdt> recipients,
        List<SLA_Action__mdt> actions
    ) {
        priorityRuleOverrides = priorities;
        tierRuleOverrides = tiers;
        businessHoursOverrides = businessHours;
        recipientOverrides = recipients;
        actionOverrides = actions;
    }

    public static void clearTestConfiguration() {
        priorityRuleOverrides = null;
        tierRuleOverrides = null;
        businessHoursOverrides = null;
        recipientOverrides = null;
        actionOverrides = null;
    }

    private static void applyTierMetadata(SlaRule rule) {
        if (rule == null) {
            return;
        }

        for (SLA_Tier__mdt tier : getTierRules()) {
            if (tier.Is_Active__c != true) {
                continue;
            }
            if (String.isBlank(rule.tierName) || (tier.Tier_Name__c != null && tier.Tier_Name__c.trim().equalsIgnoreCase(rule.tierName.trim()))) {
                rule.tierName = tier.Tier_Name__c;
                break;
            }
        }
    }

    private static List<SLA_Priority__mdt> getPriorityRules() {
        if (priorityRuleOverrides != null) {
            return priorityRuleOverrides;
        }
        return [
            SELECT MasterLabel, DeveloperName, Priority_Name__c, Warning_Hours__c, Escalation_Hours__c, Tier_Name__c, Recipient_Name__c, Action_Name__c, Is_Active__c
            FROM SLA_Priority__mdt
            WHERE Is_Active__c = true
        ];
    }

    private static List<SLA_Tier__mdt> getTierRules() {
        if (tierRuleOverrides != null) {
            return tierRuleOverrides;
        }
        return [
            SELECT MasterLabel, DeveloperName, Tier_Name__c, Is_Active__c
            FROM SLA_Tier__mdt
            WHERE Is_Active__c = true
        ];
    }

    private static List<SLA_Business_Hours__mdt> getBusinessHoursRules() {
        if (businessHoursOverrides != null) {
            return businessHoursOverrides;
        }
        return [
            SELECT MasterLabel, DeveloperName, Threshold_Hours__c, Is_Active__c
            FROM SLA_Business_Hours__mdt
            WHERE Is_Active__c = true
        ];
    }

    private static List<SLA_Escalation_Recipient__mdt> getRecipients() {
        if (recipientOverrides != null) {
            return recipientOverrides;
        }
        return [
            SELECT MasterLabel, DeveloperName, Email__c, Recipient_Name__c, Is_Active__c
            FROM SLA_Escalation_Recipient__mdt
            WHERE Is_Active__c = true
        ];
    }

    private static List<SLA_Action__mdt> getActions() {
        if (actionOverrides != null) {
            return actionOverrides;
        }
        return [
            SELECT MasterLabel, DeveloperName, Action_Type__c, Action_Name__c, Is_Active__c
            FROM SLA_Action__mdt
            WHERE Is_Active__c = true
        ];
    }

    private static SLA_Escalation_Recipient__mdt getRecipientByName(String recipientName) {
        for (SLA_Escalation_Recipient__mdt recipient : getRecipients()) {
            if (recipient.Recipient_Name__c != null && recipient.Recipient_Name__c.trim().equalsIgnoreCase(recipientName.trim())) {
                return recipient;
            }
        }
        return null;
    }

    private static SLA_Action__mdt getActionByName(String actionName) {
        for (SLA_Action__mdt action : getActions()) {
            if (action.Action_Name__c != null && action.Action_Name__c.trim().equalsIgnoreCase(actionName.trim())) {
                return action;
            }
        }
        return null;
    }
}
