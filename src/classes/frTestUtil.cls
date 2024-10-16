public class frTestUtil {
    public static void assertNoErrors() {
        List<Error__c> errors = [SELECT Error__c, Funraise_Object__c FROM Error__c];
        String errorsStr = '';
        for(Error__c error : errors) {
            errorsStr +=  '==Object ' + error.Funraise_Object__c + '==\n' +
                'Error: ' +error.Error__c + '\n';
        }
        System.assertEquals(0, errors.size(), 'There were unexpected errors. Errors:' + errorsStr);
        
        List<Sync_Attempt__c> savedSyncAttempts = [SELECT Id, Type__c FROM Sync_Attempt__c];
        String syncErrorStr = '';
        for(Sync_Attempt__c attempt : savedSyncAttempts) {
            syncErrorStr += '==Type: ' + attempt.Type__c;
        }
        System.assertEquals(0, savedSyncAttempts.size(), 'There were unexpected saved sync attempts:' + syncErrorStr);
    }
    
        
    public static void createTestPost(Map<String, Object> request) {
        createTestPost(Blob.valueOf(Json.serialize(request)));
    }
    
    public static void createTestPost(Blob requestBody) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1';
        req.httpMethod = 'POST';
        req.requestBody = requestBody;
        RestContext.request = req;
        RestContext.response = res;
    }
}