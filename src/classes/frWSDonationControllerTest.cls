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
    private static void createMapping(String frField, String sfField) {
        insert new frMapping__c(Name = frField+sfField, fr_Name__c = frField, sf_Name__c = sfField, Type__c = frDonation.TYPE);
    }
    static testMethod void syncEntity_newDonor() {  
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/donation';
        req.httpMethod = 'POST';

        req.requestBody = Blob.valueOf(getTestPayload());
        RestContext.request = req;
        RestContext.response = res;

        createMapping('name', 'Name');
        createMapping('donation_cretime', 'CloseDate');

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
        Opportunity newOpportunity = [SELECT Id, fr_ID__c FROM Opportunity WHERE Id = :oppId];
    }

    static testMethod void syncEntity_existingDonor() { 
        Contact testContact = new Contact(FirstName = 'Bruce', LastName = 'Wayne', 
            Email = 'bruce.wayne@wayne.example.com', fr_ID__c = '856');
        insert testContact;

        Long currentMillis = Datetime.now().getTime();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/donation';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(getTestPayload());
        RestContext.request = req;
        RestContext.response = res;
        createMapping('name', 'Name');
        createMapping('donation_cretime', 'CloseDate');
        Test.startTest();

        frWSDonationController.syncEntity();

        Test.stopTest();

        MockResponse response = (MockResponse) JSON.deserialize(res.responseBody.toString(), MockResponse.class);
        
        List<String> responseErrors = response.errors;
        System.assertEquals(0, responseErrors.size(), 
            'They were unexpected errors. Errors: '+responseErrors);
        List<Error__c> errors = [SELECT Error__c FROM Error__c];
        String errorsStr = '';
        for(Error__c error : errors) {
            errorsStr += error.Error__c + '\n';
        }
        System.assertEquals(0, errors.size(), 'There were unexpected errors. Errors:' + errorsStr);
        System.assert(response.result, 'There were no errors expected, result should be successful save');
        
        Id oppId = response.id;
        System.assert(String.isNotBlank(oppId), 
            'There was not an opportunity Id in the response as expected');
        Opportunity newOpportunity = [SELECT Id, fr_ID__c, fr_Donor__c FROM Opportunity WHERE Id = :oppId];
        System.assertEquals(testContact.Id, newOpportunity.fr_Donor__c, 
            'The funraise sf donor id was not populated to the opportunity\'s contact lookup field');
    }

    public class MockResponse {
        String id;
        List<String> errors;
        Boolean result;
    }

    private static String getTestPayload() {
        return 
        '{"id":2048,'+
        '"organizationId":"ae8d412b-db97-49dc-8c8c-5bfe0f41fc6d",'+
        '"amount":1E+1,'+
        '"name":"alex test02221503 - Funraise 2017-04-24T23:45:10.493Z",'+
        '"donorId":856,'+
        '"anonymous":false,'+
        '"status":"Complete",'+
        '"formName":"Bitpay Widget Test",'+
        '"url":"file:///home/alex/Desktop/form.html",'+
        '"offline":false,'+
        '"recurring":true,'+
        '"memo":null,'+
        '"dedicationMessage":null,'+
        '"dedicationName":null,'+
        '"dedicationEmail":null,'+
        '"dedicationType":null,'+
        '"tags":null,'+
        '"recurringSequence":3,'+
        '"operationsTip":false,'+
        '"note":null,'+
        '"campaignGoalId":null,'+
        '"donation_cretime":1493077510493}';
    }
}