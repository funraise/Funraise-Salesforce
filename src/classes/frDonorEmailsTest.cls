/*
 *
 *  Copyright (c) 2016, Funraise Inc
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are met:
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *  3. All advertising materials mentioning features or use of this software
 *     must display the following acknowledgement:
 *     This product includes software developed by the <organization>.
 *  4. Neither the name of the <organization> nor the
 *     names of its contributors may be used to endorse or promote products
 *     derived from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY FUNRAISE INC ''AS IS'' AND ANY
 *  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 *  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 *  DISCLAIMED. IN NO EVENT SHALL FUNRAISE INC BE LIABLE FOR ANY
 *  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 *  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 *  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 *
 * PURPOSE:
 *
 *
 *
 * CREATED: 2018 Funraise Inc - https://funraise.io
 * AUTHOR: Jordan Speer
 */
@isTest
public class frDonorEmailsTest {
    static testMethod void createExistingContact_test() {
        String funraiseId = '123456';
        Contact testContact = new Contact(
            FirstName = 'Bruce', LastName = 'Wayne', Email = 'bruce@wayne.example.com',
            MailingStreet = '1007 Mountain Drive', MailingCity = 'Gotham', MailingState = 'NJ',
            MailingPostalCode = '12345', MailingCountry = 'United States', fr_ID__c = funraiseId
        );
        insert testContact;

        Map<String, Object> request = new Map<String, Object>();
        request.put('donorId', funraiseId);
        request.put('id', 4);
        request.put('messageId', 'db92570b-766b-46b9-8b7a-a0c7efa92053');
        request.put('correlationId', '4aeeCRcARIamde0uiZAr6Q');
        request.put('fromAddress', 'test@funraise.io');
        request.put('fromName', 'Bob Hope');
        request.put('toAddress', 'notfunraise@funraise.io');
        request.put('statusCode', 202);
        request.put('sentDate', 1536184380L);
        request.put('subject', 'Hello there!');

        Test.startTest();
        String donorEmailsResponse = frDonorEmails.create(request);
        Test.stopTest();

        Contact[] newContact = [SELECT Id, fr_ID__c FROM Contact WHERE fr_ID__c = :funraiseId];
        String[] toAddress = new String[]{'notfunraise@funraise.io'};
        EmailMessage newEmail = [SELECT fromAddress FROM EmailMessage WHERE fr_Email_ID__c = '4'];
        System.assertEquals('test@funraise.io', newEmail.fromAddress, 'The fromAddress was not correct');
    }

    static testMethod void createNoExistingContact_test() {
        String funraiseId = '2314';

        Map<String, Object> request = new Map<String, Object>();
        request.put('id', 2314);
        request.put('emailId', 4);
        request.put('messageId', 'db92570b-766b-46b9-8b7a-a0c7efa92053');
        request.put('correlationId', '4aeeCRcARIamde0uiZAr6Q');
        request.put('statusCode', 202);
        request.put('sentDate', 1536184380L);
        request.put('subject', 'Hello there!');
        
        Test.startTest();
        String donorEmailsResponse = frDonorEmails.create(request);
        Test.stopTest();
        
        System.assertEquals(null, donorEmailsResponse, 'The donor was not null');
    }

    static testMethod void createEmailNoEmailId_test() {
        String funraiseId = '123456';
        Contact testContact = new Contact(
            FirstName = 'Bruce', LastName = 'Wayne', Email = 'bruce@wayne.example.com',
            MailingStreet = '1007 Mountain Drive', MailingCity = 'Gotham', MailingState = 'NJ',
            MailingPostalCode = '12345', MailingCountry = 'United States', fr_ID__c = funraiseId
        );
        insert testContact;

        Map<String, Object> request = new Map<String, Object>();
        request.put('donorId', funraiseId);
        request.put('messageId', 'db92570b-766b-46b9-8b7a-a0c7efa92053');
        request.put('correlationId', '4aeeCRcARIamde0uiZAr6Q');
        request.put('fromAddress', 'test111@funraise.io');
        request.put('fromName', 'Bob Hope');
        request.put('toAddress', 'notfunraise111@funraise.io');
        request.put('statusCode', 202);
        request.put('sentDate', 1536184380L);
        request.put('subject', 'Hello there!');

        Test.startTest();
        String donorEmailsResponse = frDonorEmails.create(request);
        Test.stopTest();
        System.debug('Response: ' + donorEmailsResponse);

        Contact[] newContact = [SELECT Id, fr_ID__c FROM Contact WHERE fr_ID__c = :funraiseId];
        String[] toAddress = new String[]{'notfunraise111@funraise.io'};
        EmailMessage newEmail = [SELECT fromAddress FROM EmailMessage WHERE FromAddress = 'test111@funraise.io'];
        System.assertEquals('test111@funraise.io', newEmail.fromAddress, 'The fromAddress was not correct');
    }
    
    static testMethod void syncEntity_test() {
        Contact testContact = frDonorTest.getTestContact();
        testContact.fr_ID__c = '856';
        insert testContact;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/donoremail';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(getTestPayload());
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();

        frWSDonorEmailController.syncEntity();

        Test.stopTest();
        
        MockResponse response = (MockResponse) JSON.deserialize(res.responseBody.toString(), MockResponse.class);

		frTestUtil.assertNoErrors();        
        Id emailId = response.id;
        System.assert(String.isNotBlank(emailId), 'There was not an email Id in the response as expected');
        EmailMessage newEmail = [SELECT fromAddress, (SELECT Id, RelationId FROM EmailMessageRelations WHERE RelationType = 'ToAddress') FROM EmailMessage WHERE Id = :emailId];
        System.assertEquals('email@funraise.io', newEmail.fromAddress, 'The funraise email address was not correct');
        System.assertEquals(1, newEmail.EmailMessageRelations.size(), 'There should be a single email relation on the message. '+newEmail.EmailMessageRelations);
        Contact supporter = [SELECT Id, fr_ID__c FROM Contact WHERE Id = :newEmail.EmailMessageRelations.get(0).RelationId];
        System.assertEquals(testContact.Id, supporter.Id, 'The email should have been associated with the contact with the same fr_ID__c as the request had');
        System.assertEquals(testContact.fr_Id__c, supporter.fr_ID__c, 'The email should have been associated with the contact referenced in the request');
    }

    public class MockResponse {
        String id;
    }

    private static String getTestPayload() {
        return '{'+
            '"donorId":856,'+
            '"id": 4,'+
            '"messageId": "db92570b-766b-46b9-8b7a-a0c7efa92053",'+
            '"correlationId": "4aeeCRcARIamde0uiZAr6Q",'+
            '"fromAddress": "email@funraise.io",' +
            '"fromName": "John Smith",' +
            '"toAddress": "testEmail@google.com",' +
            '"statusCode": 202,'+
            '"sentDate": ' + 1536184380L + ','+
            '"subject": "Hello there"'+
            '}';
    }
}