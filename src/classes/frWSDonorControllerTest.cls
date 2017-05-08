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
public class frWSDonorControllerTest {
    static testMethod void syncEntity_test() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/donor';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(getTestPayload());
        RestContext.request = req;
        RestContext.response = res;

        createMapping('firstName', 'FirstName');
        createMapping('lastName', 'LastName');
        createMapping('email', 'email');
        createMapping('address1', 'MailingStreet');
        createMapping('city', 'MailingCity');
        createMapping('state', 'MailingState');
        createMapping('postalCode', 'MailingPostalCode');
        createMapping('country', 'MailingCountry');
        createMapping('donor_cretime', 'BirthDate');
        Test.startTest();

        frWSDonorController.syncEntity();

        Test.stopTest();
        

        MockResponse response = (MockResponse) JSON.deserialize(res.responseBody.toString(), MockResponse.class);

        
        Id contactId = response.id;
        System.assert(String.isNotBlank(contactId), 
            'There was not an contact Id in the response as expected');
        Contact newContact = [SELECT Id, fr_ID__c FROM Contact WHERE Id = :contactId];
        System.assertEquals('856', newContact.fr_ID__c, 'The funraise donor id was not populated to the contact field');
    }

    static testMethod void syncEntity_existing_match_funraise_id() {
        Contact existing = new Contact(LastName = 'Test', FirstName = 'Existing', Email = 'testExisting@example.com', fr_ID__c = '856');
        Contact noMatch = new Contact(LastName = 'nomatch', FirstName = 'nomatch', Email = 'nomatch@example.com', fr_ID__c = '111');
        insert new List<Contact>{existing, noMatch};

        Integer countBeforeSync = [SELECT COUNT() FROM Contact];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/donor';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(getTestPayload());
        RestContext.request = req;
        RestContext.response = res;

        createMapping('firstName', 'FirstName');
        createMapping('lastName', 'LastName');
        createMapping('email', 'email');
        createMapping('address1', 'MailingStreet');
        createMapping('city', 'MailingCity');
        createMapping('state', 'MailingState');
        createMapping('postalCode', 'MailingPostalCode');
        createMapping('country', 'MailingCountry');
        Test.startTest();

        frWSDonorController.syncEntity();

        Test.stopTest();
        

        MockResponse response = (MockResponse) JSON.deserialize(res.responseBody.toString(), MockResponse.class);

        
        Id contactId = response.id;
        System.assert(String.isNotBlank(contactId), 
            'There was not an contact Id in the response as expected');
        System.assertEquals(existing.Id, contactId, 'The existing contact should have been used');
        Contact newContact = [SELECT Id, fr_ID__c, Email FROM Contact WHERE Id = :contactId];
        Integer countAfterSync = [SELECT COUNT() FROM Contact];
        System.assertEquals(countBeforeSync, countAfterSync, 'No additional contacts should have been created');
    }

    static testMethod void syncEntity_existing_match_email() {
        Contact existing = new Contact(LastName = 'Test', FirstName = 'Existing', Email = 'alextest02221503@example.com');
        Contact noMatch = new Contact(LastName = 'nomatch', FirstName = 'nomatch', Email = 'nomatch@example.com', fr_ID__c = '111');
        insert new List<Contact>{existing, noMatch};

        Integer countBeforeSync = [SELECT COUNT() FROM Contact];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/donor';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(getTestPayload());
        RestContext.request = req;
        RestContext.response = res;

        createMapping('firstName', 'FirstName');
        createMapping('lastName', 'LastName');
        createMapping('email', 'email');
        createMapping('address1', 'MailingStreet');
        createMapping('city', 'MailingCity');
        createMapping('state', 'MailingState');
        createMapping('postalCode', 'MailingPostalCode');
        createMapping('country', 'MailingCountry');
        Test.startTest();

        frWSDonorController.syncEntity();

        Test.stopTest();
        

        MockResponse response = (MockResponse) JSON.deserialize(res.responseBody.toString(), MockResponse.class);

        
        Id contactId = response.id;
        System.assert(String.isNotBlank(contactId), 
            'There was not an contact Id in the response as expected');
        System.assertEquals(existing.Id, contactId, 'The existing contact should have been used');
        Contact newContact = [SELECT Id, fr_ID__c FROM Contact WHERE Id = :contactId];
        Integer countAfterSync = [SELECT COUNT() FROM Contact];
        System.assertEquals(countBeforeSync, countAfterSync, 'No additional contacts should have been created');
        System.assertEquals('856', newContact.fr_ID__c, 'The funraise Id should be populated on the existing contact matched by email');
    }

    static testMethod void syncEntity_existing_match_address() {
        Contact existing = new Contact(LastName = 'test02221503', FirstName = 'alex', Email = 'testExisting@example.com',
            MailingStreet = '1234 S Street st',
            MailingCity = 'Test City',
            MailingState = 'AZ',
            MailingPostalCode = '85008',
            MailingCountry = 'United States'
        );

        Contact noMatch = new Contact(LastName = 'nomatch', FirstName = 'nomatch', Email = 'nomatch@example.com', fr_ID__c = '111');
        insert new List<Contact>{existing, noMatch};

        Integer countBeforeSync = [SELECT COUNT() FROM Contact];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/donor';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(getTestPayload());
        RestContext.request = req;
        RestContext.response = res;

        createMapping('firstName', 'FirstName');
        createMapping('lastName', 'LastName');
        createMapping('email', 'email');
        createMapping('address1', 'MailingStreet');
        createMapping('city', 'MailingCity');
        createMapping('state', 'MailingState');
        createMapping('postalCode', 'MailingPostalCode');
        createMapping('country', 'MailingCountry');
        Test.startTest();

        frWSDonorController.syncEntity();

        Test.stopTest();
        

        MockResponse response = (MockResponse) JSON.deserialize(res.responseBody.toString(), MockResponse.class);

        
        Id contactId = response.id;
        System.assert(String.isNotBlank(contactId), 
            'There was not an contact Id in the response as expected');
        System.assertEquals(existing.Id, contactId, 'The existing contact should have been used');
        Contact newContact = [SELECT Id, fr_ID__c FROM Contact WHERE Id = :contactId];
        Integer countAfterSync = [SELECT COUNT() FROM Contact];
        System.assertEquals(countBeforeSync, countAfterSync, 'No additional contacts should have been created');
        System.assertEquals('856', newContact.fr_ID__c, 'The funraise Id should be populated on the existing contact matched by email');
    }

    static testMethod void syncEntity_badMappings() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/donor';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(getTestPayload());
        RestContext.request = req;
        RestContext.response = res;

        createMapping('firstName', 'FirstName');
        createMapping('lastName', 'LastName');
        createMapping('email', 'email');
        createMapping('address1', 'MailingStreet');
        createMapping('city', 'MailingCity');
        createMapping('state', 'MailingState');
        createMapping('postalCode', 'MailingPostalCode');
        createMapping('country', 'MailingCountry');

        //bad mapping for date
        createMapping('institutionCategory', 'BirthDate');
        //bad mapping for datetime
        createMapping('p2gScore', 'LastCURequestDate');
        Test.startTest();

        frWSDonorController.syncEntity();

        Test.stopTest();
        
        List<Error__c> errors = [SELECT Error__c FROM Error__c];
        String errorsStr = '';
        for(Error__c error : errors) {
            errorsStr += error.Error__c + '\n';
        }
        System.assertEquals(2, errors.size(), 'Only 2 bad mapping errors were expected (Date and Datetime fields): Errors:' + errorsStr);

        MockResponse response = (MockResponse) JSON.deserialize(res.responseBody.toString(), MockResponse.class);

        //but even with bad field mappings the record should still come over correctly
        Id contactId = response.id;
        System.assert(String.isNotBlank(contactId), 
            'There was not an contact Id in the response as expected');
        Contact newContact = [SELECT Id, fr_ID__c FROM Contact WHERE Id = :contactId];

        System.assertEquals('856', newContact.fr_ID__c, 'The funraise donor id was not populated to the contact field');
    }

    private static void createMapping(String frField, String sfField) {
        insert new frMapping__c(Name = frField+sfField, fr_Name__c = frField, sf_Name__c = sfField, Type__c = frDonor.TYPE);
    }

    public class MockResponse {
        String id;
        Boolean result;
    }

    private static String getTestPayload() {
        return '{'+
                '"id":856,'+
                '"organizationId":"ae8d412b-db97-49dc-8c8c-5bfe0f41fc6d",'+
                '"email":"alextest02221503@example.com",'+
                '"firstName":"alex",'+
                '"lastName":"test02221503",'+
                '"name":"alex test02221503",'+
                '"institutionName":null,'+
                '"institutionCategory":"Individual",'+
                '"address1":"1234 S Street st",'+
                '"address2":null,'+
                '"city":"Test City",'+
                '"state":"AZ",'+
                '"postalCode":"85008",'+
                '"country":"United States",'+
                '"notes":null,'+
                '"age":67,'+
                '"gender":"F",'+
                '"p2gScore":"3|6 - Average",'+
                '"netWorth":"$100MM-$500MM",'+
                '"income":"$10MM-$25MM",'+
                '"giftCapacity":"$300K-$500K",'+
                '"annualDonations":"$10K-$25K",'+
                '"realEstate":"$5MM-$10MM",'+
                '"photoUrl":null,'+
                '"linkedinUrl":null,'+
                '"facebookUrl":null,'+
                '"twitterUrl":null,'+
                '"employerName":null,'+
                '"jobTitle":null,'+
                '"homeowner":null,'+
                '"maritalStatus":null,'+
                '"influencerScore":null,'+
                '"education":null,'+
                '"donorType":"RECURRING",'+
                '"totalDonationAmount":3E+1,'+
                '"totalDonationCount":3,'+
                '"lastDonationDate":1493077510493,'+
                '"firstDonationDate":1487801043934,'+
                '"totalSoftCreditAmount":null,'+
                '"totalSoftCreditCount":null,'+
                '"fundraiserDonationAmount":null,'+
                '"fundraiserDonationCount":null,'+
                '"fundraiser":false,'+
                '"donor_cretime":1487801043597'+
        '}';
    }
}