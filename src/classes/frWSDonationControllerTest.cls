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
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/donation';
        req.httpMethod = 'POST';

        req.requestBody = Blob.valueOf(getTestPayload());

        RestContext.request = req;
        RestContext.response = res;

        createMapping('name', 'Name');
        createMapping('name', 'Description');
        createMapping('amount', 'amount');
        createMapping('donation_cretime', 'CloseDate');
        insert new frMapping__c(Name = 'Test String', Is_Constant__c = true, Constant_Value__c = 'Closed Won', sf_Name__c = 'StageName', Type__c = frDonation.TYPE);
        insert new frMapping__c(Name = 'Test Percent', Is_Constant__c = true, Constant_Value__c = '95', sf_Name__c = 'Probability', Type__c = frDonation.TYPE);
        insert new frMapping__c(Name = 'Test Integer', Is_Constant__c = true, Constant_Value__c = String.valueOf(Date.today().year()), sf_Name__c = 'fiscalyear', Type__c = frDonation.TYPE);
        insert new frMapping__c(Name = 'Test Double', Is_Constant__c = true, Constant_Value__c = '1.5', sf_Name__c = 'totalopportunityquantity', Type__c = frDonation.TYPE);

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
        Opportunity newOpportunity = [SELECT Id, fr_ID__c, StageName, Name, Description, Probability, FiscalYear, TotalOpportunityQuantity FROM Opportunity WHERE Id = :oppId];
        System.assertEquals('Closed Won', newOpportunity.StageName, 'The constant mapping for StageName was not used');
        System.assertEquals(95, newOpportunity.Probability, 'The constant mapping for Probability was not used');
        System.assertEquals(2017, newOpportunity.FiscalYear, 'The constant mapping for Fiscal Year was not used');
        System.assertEquals(1.5, newOpportunity.TotalOpportunityQuantity, 'The constant mapping for Total Opportunity Quantity was not used');
        Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(req.requestBody.toString());
        String expectedNameAndDesc = (String)body.get('name');
        //assert that we can use the same funraise field to 2 different SF fields
        System.assertEquals(expectedNameAndDesc, newOpportunity.Name, 'The mapping for name should have been applied');
        System.assertEquals(expectedNameAndDesc, newOpportunity.Description, 'The mapping for desc should have been applied');
    }

    static testMethod void syncEntity_existingDonor() { 
        Contact testContact = frDonorTest.getTestContact();
        insert testContact;

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
        assertNoErrors(response);
        
        Id oppId = response.id;
        System.assert(String.isNotBlank(oppId), 
            'There was not an opportunity Id in the response as expected');
        Opportunity newOpportunity = [SELECT Id, fr_ID__c, fr_Donor__c FROM Opportunity WHERE Id = :oppId];
        System.assertEquals(testContact.Id, newOpportunity.fr_Donor__c, 
            'The funraise sf donor id was not populated to the opportunity\'s contact lookup field');
    }
    
    
    static testMethod void syncEntity_CampaignDonation() { 
        Contact testContact = frDonorTest.getTestContact();
        insert testContact;
        
        Campaign testCampaign = new Campaign(fr_ID__c = '10', Name = 'Test Campaign', 
                                             ExpectedRevenue = 123, Description = 'Test', Status = 'Published');
        insert testCampaign;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/donation';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(getTestPayloadCampaign());
        RestContext.request = req;
        RestContext.response = res;
        createMapping('name', 'Name');
        createMapping('donation_cretime', 'CloseDate');
        Test.startTest();

        frWSDonationController.syncEntity();

        Test.stopTest();

        MockResponse response = (MockResponse) JSON.deserialize(res.responseBody.toString(), MockResponse.class);
        assertNoErrors(response);
        
        Id oppId = response.id;
        System.assert(String.isNotBlank(oppId), 
            'There was not an opportunity Id in the response as expected');
        Opportunity newOpportunity = [SELECT Id, fr_ID__c, fr_Donor__c, CampaignId FROM Opportunity WHERE Id = :oppId];
        System.assertEquals(testContact.Id, newOpportunity.fr_Donor__c, 
            'The funraise sf donor id was not populated to the opportunity\'s contact lookup field');
        Campaign newCampaign = [SELECT Id FROM Campaign WHERE fr_ID__c = '10'];
        System.assertEquals(newCampaign.Id, newOpportunity.CampaignId, 
            'The campaign Id was not added to the donation');
    }
    
    static testMethod void syncEntity_donationStatusDefaulting() { 
        Contact testContact = frDonorTest.getTestContact();
        insert testContact;
        
        Campaign testCampaign = new Campaign(fr_ID__c = '10', Name = 'Test Campaign', 
                                             ExpectedRevenue = 123, Description = 'Test', Status = 'Published');
        insert testCampaign;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/donation';
        req.httpMethod = 'POST';
        Map<String, Object> request = getTestRequest();
        request.put('status', 'Refunded');
        req.requestBody = Blob.valueOf(Json.serialize(request));
        RestContext.request = req;
        RestContext.response = res;
        createMapping('name', 'Name');
        createMapping('donation_cretime', 'CloseDate');
        Test.startTest();

        frWSDonationController.syncEntity();

        Test.stopTest();

        MockResponse response = (MockResponse) JSON.deserialize(res.responseBody.toString(), MockResponse.class);
        assertNoErrors(response);
        
        Id oppId = response.id;
        System.assert(String.isNotBlank(oppId), 
            'There was not an opportunity Id in the response as expected');
        Opportunity newOpportunity = [SELECT Id, StageName, fr_ID__c, fr_Donor__c FROM Opportunity WHERE Id = :oppId];
		System.assertEquals('Closed Lost', newOpportunity.StageName, 'A status of refunded should have resulted in a Closed Lost stage');
    }
    
    static testMethod void syncEntity_newOpportunityRoleMappings() { 
        Contact donor = frDonorTest.getTestContact();
        donor.fr_Id__c = '1';
        donor.Email = 'donor@example.com';
        Contact fundraiser = frDonorTest.getTestContact();
        fundraiser.fr_Id__c = '2';
        fundraiser.Email = 'fundraiser@example.com';
        Contact teamCaptain = frDonorTest.getTestContact();
        teamCaptain.fr_Id__c = '3';
        teamCaptain.Email = 'teamCaptain@example.com';
        insert new List<Contact>{donor, fundraiser, teamCaptain};

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/donation';
        req.httpMethod = 'POST';
        Map<String, Object> request = getTestRequest();
        request.put('opportunityContactMappingDisabled', 'false');
        request.put('donorId', donor.fr_Id__c);
        request.put('fundraiserId', fundraiser.fr_ID__c);
        request.put('teamCaptainId', teamCaptain.fr_ID__c);
        req.requestBody = Blob.valueOf(Json.serialize(request));
        RestContext.request = req;
        RestContext.response = res;
        createMapping('name', 'Name');
        createMapping('donation_cretime', 'CloseDate');
        Test.startTest();

        frWSDonationController.syncEntity();

        Test.stopTest();

        MockResponse response = (MockResponse) JSON.deserialize(res.responseBody.toString(), MockResponse.class);
        assertNoErrors(response);
        
        Id oppId = response.id;
        System.assert(String.isNotBlank(oppId), 
            'There was not an opportunity Id in the response as expected');
        Opportunity newOpportunity = [SELECT Id, fr_ID__c, fr_Donor__c, (SELECT Id, ContactId, Role FROM OpportunityContactRoles) FROM Opportunity WHERE Id = :oppId];
        List<OpportunityContactRole> roles = newOpportunity.OpportunityContactRoles;
        System.assertEquals(3, roles.size(), 'Expected to be a role for donor, fundraiser, and team captain');
        for(OpportunityContactRole role : roles) {
            if(role.Role == frDonation.OPP_ROLE_DONOR) {
                System.assertEquals(donor.Id, role.ContactId, 'The donor should have the donor opportunity role');                
            } else if(role.Role == frDonation.OPP_ROLE_FUNDRAISER) {
                System.assertEquals(fundraiser.Id, role.ContactId, 'The fundraiser should have the fundraiser opportunity role');                
            } else if(role.Role == frDonation.OPP_ROLE_TEAM_CAPTAIN) {
                System.assertEquals(teamCaptain.Id, role.ContactId, 'The team captain should have the team captain opportunity role');                
            } else {
                System.assert(false, 'An unexpected opportunity contact role was created from a funraise request');
            }
        }
    }
    
    static testMethod void syncEntity_newOpportunityRoleMappings_missingContacts() { 
        Contact donor = frDonorTest.getTestContact();
        donor.fr_Id__c = '1';
        donor.Email = 'donor@example.com';
        Contact fundraiser = frDonorTest.getTestContact();
        fundraiser.fr_Id__c = '2';
        fundraiser.Email = 'fundraiser@example.com';
        Contact teamCaptain = frDonorTest.getTestContact();
        teamCaptain.fr_Id__c = '3';
        teamCaptain.Email = 'teamCaptain@example.com';
        insert new List<Contact>{donor, fundraiser, teamCaptain};

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/donation';
        req.httpMethod = 'POST';
        Map<String, Object> request = getTestRequest();
        request.put('opportunityContactMappingDisabled', 'false');
        request.put('donorId', donor.fr_Id__c);
        request.put('fundraiserId', fundraiser.fr_ID__c+'1');
        request.put('teamCaptainId', teamCaptain.fr_ID__c+'1');
        req.requestBody = Blob.valueOf(Json.serialize(request));
        RestContext.request = req;
        RestContext.response = res;
        createMapping('name', 'Name');
        createMapping('donation_cretime', 'CloseDate');
        Test.startTest();

        frWSDonationController.syncEntity();

        Test.stopTest();

        MockResponse response = (MockResponse) JSON.deserialize(res.responseBody.toString(), MockResponse.class);
        
        Id oppId = response.id;
        System.assert(String.isNotBlank(oppId), 
            'There was not an opportunity Id in the response as expected');
        Opportunity newOpportunity = [SELECT Id, fr_ID__c, fr_Donor__c, (SELECT Id, ContactId, Role FROM OpportunityContactRoles) FROM Opportunity WHERE Id = :oppId];
        List<OpportunityContactRole> roles = newOpportunity.OpportunityContactRoles;
        System.assertEquals(1, roles.size(), 'Since the request had ids that did not exist in SF, no roles should have been created except for the donor');
        System.assertEquals(2, [SELECT COUNT() FROM Error__c], 'There should be 3 error logs for missing supporters that prevented opp roles from being created');
    }
    
    private static void assertNoErrors(MockResponse response) {
        List<String> responseErrors = response.errors;
        System.assertEquals(0, responseErrors.size(), 
            'They were unexpected errors. Errors: '+responseErrors);
        List<Error__c> errors = [SELECT Error__c FROM Error__c];
        String errorsStr = '';
        for(Error__c error : errors) {
            errorsStr += error.Error__c + '\n';
        }
        System.assertEquals(0, errors.size(), 'There were unexpected errors. Errors:' + errorsStr);
        System.assert(response.success, 'There were no errors expected, result should be successful save');
    }
    
    private static void createMapping(String frField, String sfField) {
        insert new frMapping__c(Name = frField+sfField, fr_Name__c = frField, sf_Name__c = sfField, Type__c = frDonation.TYPE);
    }

    public class MockResponse {
        String id;
        List<String> errors;
        Boolean success;
    }

    private static String getTestPayload() {
        return Json.serialize(getTestRequest());
    }
    
    private static String getTestPayloadCampaign() {
        Map<String, Object> testRequest = getTestRequest();
        testRequest.put('campaignGoalId', 10);
        return Json.serialize(testRequest);
    }
    
    private static Map<String, Object> getTestRequest() {
        Map<String, Object> request = new Map<String, Object>();
        request.put('id', 2048);
        request.put('organizationId', 'ae8d412b-db97-49dc-8c8c-5bfe0f41fc6d');
        request.put('amount', 10);
        request.put('name', 'alex test02221503 - Funraise 2017-04-24T23:45:10.493Z');
        request.put('donorId', 123456);
        request.put('anonymous', false);
        request.put('status', 'Complete');
        request.put('pledge', false);
        request.put('formName', 'Bitpay Widget Test');
        request.put('url', 'file:///home/alex/Desktop/form.html');
        request.put('offline', false);
        request.put('recurring', true);
        request.put('memo', null);
        request.put('dedicationMessage', null);
        request.put('dedicationName', null);
        request.put('dedicationEmail', null);
        request.put('dedicationType', null);
        request.put('tags', null);
        request.put('recurringSequence', 3);
        request.put('operationsTip', false);
        request.put('note', null);
        request.put('campaignGoalId', null);
        request.put('donation_cretime', 1493077510493L);
        request.put('opportunityContactMappingDisabled', 'true');
        request.put('fundraiserId', null);
        request.put('teamCaptainId', null);
        return request;
    }
}