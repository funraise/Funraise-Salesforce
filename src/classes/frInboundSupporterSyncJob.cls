public class frInboundSupporterSyncJob implements Queueable, Database.AllowsCallouts {
    private static final String SECRET_HEADER = 'X-Funraise-Salesforce-Secret';
    private static final Integer TIMEOUT_MILLISECONDS = 4000;
    private List<frInboundSupporterSync.WorkItem> workItems;

    public frInboundSupporterSyncJob(List<frInboundSupporterSync.WorkItem> workItems) {
        this.workItems = workItems == null ? new List<frInboundSupporterSync.WorkItem>() : workItems;
    }

    public void execute(QueueableContext context) {
        frInboundSettings__c settings = frInboundSupporterSync.getSettings();
        if (!frInboundSupporterSync.isConfigured(settings)) {
            return;
        }

        Http http = new Http();
        for (frInboundSupporterSync.WorkItem workItem : workItems) {
            sendUpdate(http, settings, workItem);
        }
    }

    private static void sendUpdate(Http http, frInboundSettings__c settings, frInboundSupporterSync.WorkItem workItem) {
        try {
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setEndpoint(endpoint(settings, workItem.funraiseId));
            request.setTimeout(TIMEOUT_MILLISECONDS);
            request.setHeader('Content-Type', 'application/json');
            request.setHeader(SECRET_HEADER, settings.Secret__c.trim());
            request.setBody(workItem.requestBody);

            HttpResponse response = http.send(request);
            if (response.getStatusCode() < 200 || response.getStatusCode() >= 300) {
                frUtil.logError(
                    frUtil.Entity.SUPPORTER,
                    workItem.funraiseId,
                    'Salesforce supporter update sync failed. Status: ' + response.getStatusCode() + '. Body: ' + response.getBody()
                );
            }
        } catch (Exception ex) {
            frUtil.logException(frUtil.Entity.SUPPORTER, workItem.funraiseId, ex);
        }
    }

    private static String endpoint(frInboundSettings__c settings, String funraiseId) {
        return 'callout:' + settings.Named_Credential__c.trim()
            + '/api/v1/salesforce/inbound/'
            + EncodingUtil.urlEncode(settings.Organization_UUID__c.trim(), 'UTF-8')
            + '/supporter/'
            + EncodingUtil.urlEncode(funraiseId, 'UTF-8');
    }
}
