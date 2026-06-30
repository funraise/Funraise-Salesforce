@IsTest
public class frInboundSupporterSyncTest {
    private static Integer calls = 0;
    private static String endpoint;
    private static String secret;
    private static String body;

    private class InboundSyncMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            calls++;
            endpoint = request.getEndpoint();
            secret = request.getHeader('X-Funraise-Salesforce-Secret');
            body = request.getBody();

            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{}');
            return response;
        }
    }

    @IsTest
    static void contactUpdateSyncsAllowlistedFields() {
        if (frUtil.hasNPCobjects()) {
            return;
        }

        insert settings(true);
        Contact contact = new Contact(
            FirstName = 'Original',
            LastName = 'Supporter',
            Email = 'original@example.org',
            fr_ID__c = '123'
        );
        insert contact;

        resetMock();
        Test.setMock(HttpCalloutMock.class, new InboundSyncMock());

        Test.startTest();
        contact.Email = 'updated@example.org';
        contact.Phone = '555-1234';
        update contact;
        Test.stopTest();

        System.assertEquals(1, calls, 'One supporter update should be sent to Funraise');
        System.assertEquals(
            'callout:Funraise_Platform/api/v1/salesforce/inbound/00000000-0000-0000-0000-000000000001/supporter/123',
            endpoint
        );
        System.assertEquals('shared-secret', secret);

        Map<String, Object> parsedBody = (Map<String, Object>)JSON.deserializeUntyped(body);
        System.assertEquals('updated@example.org', parsedBody.get('email'));
        System.assertEquals('555-1234', parsedBody.get('phone'));
    }

    @IsTest
    static void contactUpdateDoesNotSyncWhenDisabled() {
        if (frUtil.hasNPCobjects()) {
            return;
        }

        insert settings(false);
        Contact contact = new Contact(LastName = 'Supporter', fr_ID__c = '123');
        insert contact;

        resetMock();
        Test.setMock(HttpCalloutMock.class, new InboundSyncMock());

        Test.startTest();
        contact.Phone = '555-1234';
        update contact;
        Test.stopTest();

        System.assertEquals(0, calls, 'Disabled inbound sync should not enqueue a callout');
    }

    @IsTest
    static void contactUpdateDoesNotSyncWhenSuppressed() {
        if (frUtil.hasNPCobjects()) {
            return;
        }

        insert settings(true);
        Contact contact = new Contact(LastName = 'Supporter', fr_ID__c = '123');
        insert contact;

        resetMock();
        Test.setMock(HttpCalloutMock.class, new InboundSyncMock());

        frInboundSupporterSync.disabled = true;
        try {
            Test.startTest();
            contact.Phone = '555-1234';
            update contact;
            Test.stopTest();
        } finally {
            frInboundSupporterSync.disabled = false;
        }

        System.assertEquals(0, calls, 'Suppressed inbound sync should not enqueue a callout');
    }

    @IsTest
    static void accountTriggerDelegatesWithoutCalloutWhenUnconfigured() {
        Account account = new Account(Name = 'Funraise Test Account');
        insert account;

        Test.startTest();
        account.Name = 'Funraise Test Account Updated';
        update account;
        Test.stopTest();
    }

    private static frInboundSettings__c settings(Boolean enabled) {
        return new frInboundSettings__c(
            Name = frInboundSupporterSync.SETTINGS_NAME,
            Enabled__c = enabled,
            Named_Credential__c = 'Funraise_Platform',
            Organization_UUID__c = '00000000-0000-0000-0000-000000000001',
            Secret__c = 'shared-secret'
        );
    }

    private static void resetMock() {
        calls = 0;
        endpoint = null;
        secret = null;
        body = null;
    }
}
