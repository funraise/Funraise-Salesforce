/*
 *
 *  Copyright (c) 2020, Funraise Inc
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
 * CREATED: 2019 Funraise Inc - https://funraise.io
 * AUTHOR: Alex Molina
 */
@isTest
public class frFundraisingEventRegistrationTest {  
    static testMethod void createEvent_throughWS() {
        Fundraising_Event__c testEvent = frFundraisingEventTest.getTestEvent();
        insert testEvent;
        
        Contact testSupporter = frDonorTest.getTestContact();
        
        Opportunity testTransaction = frDonationTest.getTestOpp();
        testTransaction.fr_Id__c = '34509';
        insert testTransaction;
                
        String funraiseId = '25';
        Map<String, Object> request = getTestRequest();
        request.put('eventId', testEvent.fr_ID__c);
        request.put('supporterId', testSupporter.fr_ID__c);
        request.put('guestOfId', testSupporter.fr_ID__c);
        request.put('transactionId', testTransaction.fr_ID__c);
        request.put('id', funraiseId);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/fundraising-event';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(Json.serialize(request));
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();

        frWSFundraisingEventRegistrationCntrlr.syncEntity();

        Test.stopTest();
        
        Fundraising_Event_Registration__c registration = [SELECT Id, fr_ID__c, Name, Attended__c, Ticket_Name__c, Ticket_Amount__c,
                                                          Ticket_Tax_Deductible_Amount__c,
                                                          Supporter__c, Fundraising_Event__c, 
                                                          Guest_Of__c, Transaction__c, First_Name__c,
                                                          Last_Name__c, Phone__c, Email__c
                                                          FROM Fundraising_Event_Registration__c WHERE fr_ID__c = :funraiseId];
        
        System.assertEquals(String.valueOf(request.get('name')), registration.Name, 'The registration name should be the property included in the request');
        System.assertEquals(String.valueOf(request.get('ticketName')), registration.Ticket_Name__c, 'The registration ticket name should be the property included in the request');
        System.assertEquals(Decimal.valueOf(String.valueOf(request.get('ticketAmount'))), registration.Ticket_Amount__c, 'The registrations amount should be the property included in the request');
        System.assertEquals(Decimal.valueOf(String.valueOf(request.get('ticketTaxDeductibleAmount'))), registration.Ticket_Tax_Deductible_Amount__c, 'The registrations tax deductible amount should be the property included in the request');
        System.assertEquals(Boolean.valueOf(request.get('attended')), registration.Attended__c, 'The registration attended flag should be the property included in the request');
        System.assertEquals(testEvent.Id, registration.Fundraising_Event__c, 'The lookup for event should have been populated with the event that has the funraise id referenced in the request');
        System.assertEquals(testSupporter.Id, registration.Supporter__c, 'The lookup for supporter should have been populated with the contact that has the funraise id referenced in the request');
        System.assertEquals(testSupporter.Id, registration.Guest_Of__c, 'The lookup for guest of should have been populated with the contact that has the funraise id referenced in the request');
        System.assertEquals(testTransaction.Id, registration.Transaction__c, 'The lookup for transaction should have been populated with the opportunity that has the funraise id referenced in the request');
        System.assertEquals(String.valueOf(request.get('firstName')), registration.First_Name__c, 'The first name should have been populated with the contact info first name in the request');
        System.assertEquals(String.valueOf(request.get('lastName')), registration.Last_Name__c, 'The last name should have been populated with the contact info last name in the request');
        System.assertEquals(String.valueOf(request.get('email')), registration.Email__c, 'The email should have been populated with the contact info email in the request');
        System.assertEquals(String.valueOf(request.get('phone')), registration.Phone__c, 'The phone should have been populated with the contact info phone in the request');
    }
    
    static testMethod void createRegistration_eventMissing() {	
        Contact testSupporter = frDonorTest.getTestContact();
        
        String funraiseId = '25';
        Map<String, Object> request = getTestRequest();
        request.put('eventId', 'nonexistent');
        request.put('supporterId', testSupporter.fr_Id__c);
        request.put('guestOfId', testSupporter.fr_Id__c);
        request.put('id', funraiseId);

        Test.startTest();
        Integer errorsBefore = [SELECT COUNT() FROM Error__c];
        new frFundraisingEventRegistration(request);
        Integer errorsAfter = [SELECT COUNT() FROM Error__c];
        Test.stopTest();

        List<Fundraising_Event_Registration__c> registrations = [SELECT Id, fr_ID__c, Name, Attended__c, Ticket_Name__c, 
                                                                 Supporter__c, Fundraising_Event__c, 
                                                                 Guest_Of__c 
                                                                 FROM Fundraising_Event_Registration__c WHERE fr_ID__c = :funraiseId];
        System.assertEquals(0, registrations.size(), 'No registrations should have been created if an event id could not be matched');
        System.assertEquals(0, errorsBefore, 'Precondition');
        System.assertEquals(1, errorsAfter, 'An error log should have been created to record that an event id could not be matched');
    }
    
    static testMethod void createRegistration_supporterMissing() {	
        Fundraising_Event__c testEvent = frFundraisingEventTest.getTestEvent();
        insert testEvent;
        
        String funraiseId = '25';
        Map<String, Object> request = getTestRequest();
        request.put('eventId', testEvent.fr_ID__c);
        request.put('supporterId', 'nonexistent');
        request.put('guestOfId', 'nonexistent');
        request.put('id', funraiseId);

        Test.startTest();
        Integer errorsBefore = [SELECT COUNT() FROM Error__c];
        new frFundraisingEventRegistration(request);
        Integer errorsAfter = [SELECT COUNT() FROM Error__c];
        Test.stopTest();

        List<Fundraising_Event_Registration__c> registrations = [SELECT Id, fr_ID__c, Name, Attended__c, Ticket_Name__c, 
                                                                 Supporter__c, Fundraising_Event__c, 
                                                                 Guest_Of__c 
                                                                 FROM Fundraising_Event_Registration__c WHERE fr_ID__c = :funraiseId];
        //TODO: remove below assert and uncomment this one once it's valid (a.k.a the master-detail field is removed)
        //System.assertEquals(1, registrations.size(), 'A registration should have been created even if a supporter id could not be matched'); 
        System.assertEquals(0, registrations.size(), 'No registrations should have been created if a supporter id could not be matched');
        System.assertEquals(0, errorsBefore, 'Precondition');
        System.assertEquals(1, errorsAfter, 'An error log should have been created to record that a supporter id could not be matched');
    }
    
    static testMethod void createRegistration_guestOfMissing() {	
        Fundraising_Event__c testEvent = frFundraisingEventTest.getTestEvent();
        insert testEvent;
        
        Contact testSupporter = frDonorTest.getTestContact();
        
        Opportunity nullStringFrIdOpp = new Opportunity(
            Name = 'Test Opportunity with null string fr_id__c',
            fr_ID__c = 'null',
            StageName = 'Closed Won',
            CloseDate = Date.today()
        );
        Opportunity nullFrIdOpp = new Opportunity(
            Name = 'Test Opportunity with null fr_id__c',
            fr_ID__c = null,
            StageName = 'Closed Won',
            CloseDate = Date.today()
        );
        Opportunity unrelatedOpp = new Opportunity(
            Name = 'Test Opportunity',
            fr_ID__c = '14532',
            StageName = 'Closed Won',
            CloseDate = Date.today()
        );
        insert new List<Opportunity>{nullStringFrIdOpp, nullFrIdOpp, unrelatedOpp};
        
        String funraiseId = '25';
        Map<String, Object> request = getTestRequest();
        request.put('eventId', testEvent.fr_ID__c);
        request.put('supporterId', testSupporter.fr_ID__c);
        request.put('guestOfId', 'nonexistent'); //not matching on guestOf is ok, we will create anyway
        request.put('id', funraiseId);

        Test.startTest();
        Integer errorsBefore = [SELECT COUNT() FROM Error__c];
        new frFundraisingEventRegistration(request);
        Integer errorsAfter = [SELECT COUNT() FROM Error__c];
        Test.stopTest();

        Fundraising_Event_Registration__c registration = [SELECT Id, fr_ID__c, Name, Attended__c, Ticket_Name__c, 
                                                          Supporter__c, Fundraising_Event__c, 
                                                          Guest_Of__c, Transaction__c
                                                          FROM Fundraising_Event_Registration__c WHERE fr_ID__c = :funraiseId];
        System.assertEquals(String.valueOf(request.get('name')), registration.Name, 'The registration name should be the property included in the request');
        System.assertEquals(String.valueOf(request.get('ticketName')), registration.Ticket_Name__c, 'The registration ticket name should be the property included in the request');
        System.assertEquals(Boolean.valueOf(request.get('attended')), registration.Attended__c, 'The registration attended flag should be the property included in the request');
        System.assertEquals(testEvent.Id, registration.Fundraising_Event__c, 'The lookup for event should have been populated with the event that has the funraise id referenced in the request');
        System.assertEquals(testSupporter.Id, registration.Supporter__c, 'The lookup for supporter should have been populated with the contact that has the funraise id referenced in the request');
        System.assertEquals(null, registration.Guest_Of__c, 'The lookup for guest of should not have been populated since the request did not specify a valid id');
        System.assertEquals(null, registration.Transaction__c, 'The lookup for transaction__c should not have been populated with an opportunity');
        System.assertEquals(0, errorsBefore, 'Precondition');
        System.assertEquals(1, errorsAfter, 'An error log should have been created to record that a guest of id could not be matched');   
    }
    
    static testMethod void createRegistration_transactionMissing() {	
        Fundraising_Event__c testEvent = frFundraisingEventTest.getTestEvent();
        insert testEvent;
        
        Contact testSupporter = frDonorTest.getTestContact();
        
        String funraiseId = '25';
        Map<String, Object> request = getTestRequest();
        request.put('eventId', testEvent.fr_ID__c);
        request.put('supporterId', testSupporter.fr_ID__c);
        request.put('guestOfId', testSupporter.fr_ID__c);
        request.put('transactionId', 'nonexistent');
        request.put('id', funraiseId);

        Test.startTest();
        Integer errorsBefore = [SELECT COUNT() FROM Error__c];
        new frFundraisingEventRegistration(request);
        Integer errorsAfter = [SELECT COUNT() FROM Error__c];
        Test.stopTest();

        Fundraising_Event_Registration__c registration = [SELECT Id, fr_ID__c, Transaction__c
                                                          FROM Fundraising_Event_Registration__c WHERE fr_ID__c = :funraiseId];
        System.assertEquals(null, registration.Transaction__c, 'The lookup for transaction__c should not have been populated with an opportunity');
        System.assertEquals(0, errorsBefore, 'Precondition');
        System.assertEquals(1, errorsAfter, 'An error log should have been created to record that a transaction could not be matched');   
    }
    
    static testMethod void deleteRegistration() {	
        Fundraising_Event_Registration__c existingRegistration = getTestRegistration();
        
        Map<String, Object> request = getTestRequest();
        request.put('eventId', existingRegistration.Fundraising_Event__r.fr_ID__c);
        request.put('supporterId', existingRegistration.Supporter__r.fr_ID__c);
        request.put('guestOfId', existingRegistration.Guest_Of__r.fr_ID__c);
        request.put('id', existingRegistration.fr_Id__c);
        request.put('deleted', true);

        Test.startTest();
        new frFundraisingEventRegistration(request);
        Test.stopTest();

        frTestUtil.assertNoErrors();
        System.assertEquals(0, [SELECT COUNT() FROM Fundraising_Event_Registration__c], 'Registration should have been deleted and therefore not returned');
    }

    private static Map<String, Object> getTestRequest() {
        Map<String, Object> request = new Map<String, Object>();
        request.put('name', '000001');
        request.put('attended', true);
        request.put('ticketName', 'Test Ticket');
        request.put('ticketAmount', 99.99);
        request.put('ticketTaxDeductibleAmount', 49.99);
        request.put('eventId', 'changeme');
        request.put('supporterId', 'changeme');
        request.put('guestOfId', 'changeme');
        request.put('transactionId', null);
        request.put('id', 'changeme');
        request.put('deleted', false);
        request.put('firstName', 'testFirstName');
        request.put('lastName', 'testLastName');
        request.put('email', 'test@example.com');
        request.put('phone', '1234567890');
        return request;
    }
    
    public static Fundraising_Event_Registration__c getTestRegistration() {
        Fundraising_Event__c testEvent = frFundraisingEventTest.getTestEvent();
        insert testEvent;
        
        Contact testSupporter = frDonorTest.getTestContact();
        
        Fundraising_Event_Registration__c registration = new Fundraising_Event_Registration__c(
            fr_ID__c = '25',
            Name = 'Test Name',
            Ticket_Name__c = 'Test Ticket Name',
            Fundraising_Event__c = testEvent.Id,
            Fundraising_Event__r = testEvent,
            Supporter__c = testSupporter.Id,
            Supporter__r = testSupporter,
            Guest_Of__c = testSupporter.Id,
            Guest_Of__r = testSupporter,
            Attended__c = false
        );
        insert registration;
        return registration;
    }
    
}