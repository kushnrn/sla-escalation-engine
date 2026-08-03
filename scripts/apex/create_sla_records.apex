// Apex script to create Custom Metadata Type records via the Metadata API.
// Run this in Execute Anonymous in your target org.
// Important: this uses a Metadata API callout pattern and requires the org
// to allow the necessary deployment endpoint behavior for the session.

public class MetadataCreateExample implements Metadata.DeployCallback {
    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        if (result.status == Metadata.DeployStatus.Succeeded) {
            System.debug('Metadata deployment succeeded.');
        } else {
            System.debug('Metadata deployment failed: ' + result.errorMessage);
            for (Metadata.DeployMessage msg : result.details.componentFailures) {
                System.debug(msg.fullName + ' :: ' + msg.problem);
            }
        }
    }
}

Metadata.CustomMetadata md = new Metadata.CustomMetadata();
md.fullName = 'SLA_Priority.Standard_High';
md.label = 'Standard High';

Metadata.CustomMetadataValue[] values = new List<Metadata.CustomMetadataValue>();
values.add(new Metadata.CustomMetadataValue());
values[0].field = 'Priority_Name__c';
values[0].value = 'High';

values.add(new Metadata.CustomMetadataValue());
values[1].field = 'Warning_Hours__c';
values[1].value = 2.0;

values.add(new Metadata.CustomMetadataValue());
values[2].field = 'Escalation_Hours__c';
values[2].value = 8.0;

values.add(new Metadata.CustomMetadataValue());
values[3].field = 'Tier_Name__c';
values[3].value = 'Gold';

values.add(new Metadata.CustomMetadataValue());
values[4].field = 'Recipient_Name__c';
values[4].value = 'Ops';

values.add(new Metadata.CustomMetadataValue());
values[5].field = 'Action_Name__c';
values[5].value = 'Notify';

values.add(new Metadata.CustomMetadataValue());
values[6].field = 'Is_Active__c';
values[6].value = true;

md.values = values;

Metadata.DeployContainer container = new Metadata.DeployContainer();
container.addMetadata(md);

MetadataCreateExample callback = new MetadataCreateExample();
Id jobId = Metadata.Operations.enqueueDeployment(container, callback);
System.debug('Enqueued deployment job Id: ' + jobId);
