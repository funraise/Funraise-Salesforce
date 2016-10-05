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
 * CREATED: 2016 Funraise Inc - https://funraise.io
 * AUTHOR: Alex Molina
 */
@isTest
public class frWSDonationControllerTest {
    static testMethod void syncEntity_newDonor() {  
        Long currentMillis = Datetime.now().getTime();

        frDonation donation = new frDonation();
        donation.setDonorId('15642');
        donation.setAmount(20);
        donation.setCretime(currentMillis);
        donation.setName('Bruce Wayne - Funraise 2010-06-01 00:00:00-07');
        donation.setAnonymous(false);
        donation.setStatus('Complete');
        donation.setId('20642');

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/donation';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(donation));
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();

        frWSDonationController.syncEntity();

        Test.stopTest();

        MockResponse response = (MockResponse) JSON.deserialize(res.responseBody.toString(), MockResponse.class);
        
        List<String> responseErrors = response.errors;
        System.assertEquals(1, responseErrors.size(), 
            'They were unexpected errors. Errors: '+responseErrors);
        System.assert(responseErrors.get(0).contains('Donor not found'), 
            'The error message was not the expected one');
        
        Id oppId = response.id;
        System.assert(String.isNotBlank(oppId), 
            'There was not an opportunity Id in the response as expected');
        Opportunity newOpportunity = [SELECT Id, fr_Funraise_ID__c FROM Opportunity WHERE Id = :oppId];
        System.assertEquals(donation.getId(), newOpportunity.fr_Funraise_ID__c, 
            'The funraise donation id was not populated to the opportunity field');
    }

    static testMethod void syncEntity_existingDonor() { 
        Contact testContact = new Contact(FirstName = 'Bruce', LastName = 'Wayne', 
            Email = 'bruce.wayne@wayne.example.com', fr_Funraise_ID__c = '15642');
        insert testContact;

        Long currentMillis = Datetime.now().getTime();

        frDonation donation = new frDonation();
        donation.setDonorId('15642');
        donation.setAmount(20);
        donation.setCretime(currentMillis);
        donation.setName('Bruce Wayne - Funraise 2010-06-01 00:00:00-07');
        donation.setAnonymous(false);
        donation.setStatus('Complete');
        donation.setId('20642');
        donation.setSfDonorId(testContact.Id);

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/donation';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(donation));
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();

        frWSDonationController.syncEntity();

        Test.stopTest();

        MockResponse response = (MockResponse) JSON.deserialize(res.responseBody.toString(), MockResponse.class);
        
        List<String> responseErrors = response.errors;
        System.assertEquals(0, responseErrors.size(), 
            'They were unexpected errors. Errors: '+responseErrors);
        
        Id oppId = response.id;
        System.assert(String.isNotBlank(oppId), 
            'There was not an opportunity Id in the response as expected');
        Opportunity newOpportunity = [SELECT Id, fr_Funraise_ID__c, fr_Funraise_Donor__c FROM Opportunity WHERE Id = :oppId];
        System.assertEquals(donation.getId(), newOpportunity.fr_Funraise_ID__c, 
            'The funraise donation id was not populated to the opportunity field');
        System.assertEquals(testContact.Id, newOpportunity.fr_Funraise_Donor__c, 
            'The funraise sf donor id was not populated to the opportunity\'s contact lookup field');
    }

    public class MockResponse {
        String id;
        List<String> errors;
    }
}