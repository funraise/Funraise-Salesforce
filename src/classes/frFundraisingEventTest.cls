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
public class frFundraisingEventTest {  
    static testMethod void createEvent_throughWS() {
        String funraiseId = '25';
        Map<String, Object> request = new Map<String, Object>();
        List<Object> startDate = new List<Object> {2019, 05, 11, 9, 0};
        List<Object> endDate = new List<Object> {2019, 05, 11, 4, 30};
        request.put('name', 'Test Event');
        request.put('description', 'This will be a fun fundraising event');
        request.put('eventStartDate', startDate);
        request.put('eventEndDate', endDate);
        request.put('id', funraiseId);
        request.put('deleted', false);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/fundraising-event';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(Json.serialize(request));
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();

        frWSFundraisingEventController.syncEntity();

        Test.stopTest();
        
        Fundraising_Event__c newEvent = [SELECT Id, fr_ID__c, Name, Description__c, Start_Date__c, End_Date__c 
                                         FROM Fundraising_Event__c WHERE fr_ID__c = :funraiseId];
        System.assertEquals(String.valueOf(request.get('name')), newEvent.Name, 'The event name should be the property included in the request');
        System.assertEquals(String.valueOf(request.get('description')), newEvent.Description__c, 'The event description should be the property included in the request');
        DateTime expectedStartDate = DateTime.newInstance(2019, 05, 11, 9, 0, 0);
        System.assertEquals(expectedStartDate, newEvent.Start_Date__c, 'The start date should have been parsed correctly');
        DateTime expectedEndDate = DateTime.newInstance(2019, 05, 11, 4, 30, 0);
        System.assertEquals(expectedEndDate, newEvent.End_Date__c, 'The end date should have been parsed correctly');
    }
    
    static testMethod void createEvent_missingDates() {	
        String funraiseId = '25';
        Map<String, Object> request = new Map<String, Object>();
        request.put('name', 'Test Event');
        request.put('description', 'This will be a fun fundraising event');
        request.put('eventStartDate', null);
        request.put('eventEndDate', null);
        request.put('id', funraiseId);
        request.put('deleted', false);

        Test.startTest();
        new frFundraisingEvent(request);
        Test.stopTest();

        Fundraising_Event__c newEvent = [SELECT Id, fr_ID__c, Name, Description__c, Start_Date__c, End_Date__c 
                                         FROM Fundraising_Event__c WHERE fr_ID__c = :funraiseId];
        System.assertEquals(String.valueOf(request.get('name')), newEvent.Name, 'The event name should be the property included in the request');
        System.assertEquals(String.valueOf(request.get('description')), newEvent.Description__c, 'The event description should be the property included in the request');
        System.assertEquals(null, newEvent.Start_Date__c, 'The start date should have been parsed correctly');
        System.assertEquals(null, newEvent.End_Date__c, 'The end date should have been parsed correctly');
    }
    
    static testMethod void createEvent_valueTooLong() {	
        String funraiseId = '25';
        Map<String, Object> request = new Map<String, Object>();
        List<Object> startDate = new List<Object> {2019, 05, 11, 9, 0};
        List<Object> endDate = new List<Object> {2019, 05, 11, 4, 30};
        String name = 'a';
        for(Integer i = 0; i < Fundraising_Event__c.Name.getDescribe().getLength() + 5; i++) {
            name += 'a';
        }
        request.put('name', name);
        request.put('description', 'This will be a fun fundraising event');
        request.put('eventStartDate', startDate);
        request.put('eventEndDate', endDate);
        request.put('id', funraiseId);
        request.put('deleted', false);

        Test.startTest();
        new frFundraisingEvent(request);
        Test.stopTest();

        Fundraising_Event__c newEvent = [SELECT Id, fr_ID__c, Name, Description__c, Start_Date__c, End_Date__c 
                                         FROM Fundraising_Event__c WHERE fr_ID__c = :funraiseId];
        System.assertEquals(String.valueOf(request.get('name')).substring(0, Fundraising_Event__c.Name.getDescribe().getLength()), newEvent.Name, 'The event name should be the property included in the request');
        System.assertEquals(String.valueOf(request.get('description')), newEvent.Description__c, 'The event description should be the property included in the request');
        DateTime expectedStartDate = DateTime.newInstance(2019, 05, 11, 9, 0, 0);
        System.assertEquals(expectedStartDate, newEvent.Start_Date__c, 'The start date should have been parsed correctly');
        DateTime expectedEndDate = DateTime.newInstance(2019, 05, 11, 4, 30, 0);
        System.assertEquals(expectedEndDate, newEvent.End_Date__c, 'The end date should have been parsed correctly');
    }
    
    static testMethod void createEvent_exception_noFunraiseId() {	
        Map<String, Object> request = new Map<String, Object>();
        request.put('name', 'Test Event');
        request.put('description', 'This will be a fun fundraising event');
        request.put('eventStartDate', null);
        request.put('eventEndDate', null);
        request.put('id', null);
        request.put('deleted', false);

        Test.startTest();
        new frFundraisingEvent(request);
        Test.stopTest();

        List<Fundraising_Event__c> events = [SELECT Id, fr_ID__c, Name, Description__c, Start_Date__c, End_Date__c 
                                         FROM Fundraising_Event__c];
        System.assertEquals(0, events.size(), 'Should not have created an event with invalid data (no funraise id provided)');
        Integer errors = [SELECT COUNT() FROM Error__c];
        System.assertEquals(1, errors, 'We expect an error to be created tracking the failure of creating the event');
    }
    
    static testMethod void updateEvent_allFields() {	
        String funraiseId = '25';
        Fundraising_Event__c existingEvent = getTestEvent();
        insert existingEvent;
        
        Map<String, Object> request = new Map<String, Object>();
        List<Object> startDate = new List<Object> {2019, 05, 11, 9, 0};
        List<Object> endDate = new List<Object> {2019, 05, 11, 4, 30};
        request.put('name', 'Test Event');
        request.put('description', 'This will be a fun fundraising event');
        request.put('eventStartDate', startDate);
        request.put('eventEndDate', endDate);
        request.put('id', funraiseId);
        request.put('deleted', false);

        Test.startTest();
        new frFundraisingEvent(request);
        Test.stopTest();

        Fundraising_Event__c newEvent = [SELECT Id, fr_ID__c, Name, Description__c, Start_Date__c, End_Date__c 
                                         FROM Fundraising_Event__c WHERE fr_ID__c = :funraiseId];
        System.assertEquals(String.valueOf(request.get('name')), newEvent.Name, 'The event name should be the property included in the request');
        System.assertEquals(String.valueOf(request.get('description')), newEvent.Description__c, 'The event description should be the property included in the request');
        DateTime expectedStartDate = DateTime.newInstance(2019, 05, 11, 9, 0, 0);
        System.assertEquals(expectedStartDate, newEvent.Start_Date__c, 'The start date should have been parsed correctly');
        DateTime expectedEndDate = DateTime.newInstance(2019, 05, 11, 4, 30, 0);
        System.assertEquals(expectedEndDate, newEvent.End_Date__c, 'The end date should have been parsed correctly');
    }
    
    static testMethod void deleteEvent() {	
        String funraiseId = '25';
        Fundraising_Event__c existingEvent = new Fundraising_Event__c(Name = 'Test Event', fr_Id__c = funraiseId);
        insert existingEvent;
        
        Map<String, Object> request = new Map<String, Object>();
        List<Object> startDate = new List<Object> {2019, 05, 11, 9, 0};
        List<Object> endDate = new List<Object> {2019, 05, 11, 4, 30};
        request.put('name', 'Test Event');
        request.put('description', 'This will be a fun fundraising event');
        request.put('eventStartDate', startDate);
        request.put('eventEndDate', endDate);
        request.put('id', funraiseId);
        request.put('deleted', true);

        Test.startTest();
        new frFundraisingEvent(request);
        
        //confirm that trying to delete a record that doesn't exist in SF also won't throw exceptions
        request.put('id', funraiseId+'52');
        Test.stopTest();

        List<Fundraising_Event__c> events = [SELECT Id, fr_ID__c, Name, Description__c, Start_Date__c, End_Date__c 
                                         FROM Fundraising_Event__c WHERE fr_ID__c = :funraiseId];
        System.assertEquals(0, events.size(), 'There should be no events matching the funraise id since it was marked as deleted');
    }
    
    public static Fundraising_Event__c getTestEvent() {
        return new Fundraising_Event__c(Name = 'Test Event 2', Description__c = 'Test Desc', fr_Id__c = '12345');
    }
}