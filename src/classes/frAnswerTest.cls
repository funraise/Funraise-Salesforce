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
* CREATED: 2020 Funraise Inc - https://funraise.io
* AUTHOR: Alex Molina
*/
@isTest
public class frAnswerTest {
    @isTest
    static void createAnswer_linkedToTransaction() {
        List<SObject> setupRecords = new List<SObject>();
        Question__c question = frQuestionTest.getTestQuestion();
        setupRecords.add(question);
        
        Opportunity opp = frDonationTest.getTestOpp();
        setupRecords.add(opp);
        insert setupRecords;
        
        Contact supporter = frDonorTest.getTestContact();
        
        String funraiseId = '25';
        Map<String, Object> request = getTestRequest();
        request.put('id', funraiseId);
        request.put('questionId', question.fr_Id__c);
        request.put('donationId', opp.fr_Id__c);
        request.put('supporterId', supporter.fr_Id__c);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/custom-question-answer';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(Json.serialize(request));
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        
        frWSCustomQuestionAnswerController.syncEntity();
        
        Test.stopTest();
        frTestUtil.assertNoErrors();
        Answer__c answer = [SELECT Id, fr_ID__c, Answer__c, Question__c, Transaction__c, Supporter__c
                            FROM Answer__c WHERE fr_ID__c = :funraiseId];
        
        System.assertEquals(String.valueOf(request.get('id')), answer.fr_Id__c, 'The ansswer id should be the property included in the request');
        System.assertEquals(String.valueOf(request.get('answer')), answer.Answer__c, 'The answer value should be the property included in the request');
        System.assertEquals(question.Id, answer.Question__c, 'The question relationship should be the property included in the request');
        System.assertEquals(opp.Id, answer.Transaction__c, 'The transaction relationship should be the property included in the request');
        System.assertEquals(supporter.Id, answer.Supporter__c, 'The supporter relationship should be the property included in the request');
    }
    
    @isTest
    static void createAnswer_linkedToRegistration() {
        Question__c question = frQuestionTest.getTestQuestion();
        insert question;
        
        Fundraising_Event_Registration__c registration = frFundraisingEventRegistrationTest.getTestRegistration();
        
        String funraiseId = '25';
        Map<String, Object> request = getTestRequest();
        request.put('id', funraiseId);
        request.put('questionId', question.fr_Id__c);
        request.put('registrationId', registration.fr_Id__c);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/custom-question-answer';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(Json.serialize(request));
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        
        frWSCustomQuestionAnswerController.syncEntity();
        
        Test.stopTest();
        frTestUtil.assertNoErrors();
        Answer__c answer = [SELECT Id, fr_ID__c, Answer__c, Question__c, Registration__c
                            FROM Answer__c WHERE fr_ID__c = :funraiseId];
        
        System.assertEquals(String.valueOf(request.get('id')), answer.fr_Id__c, 'The ansswer id should be the property included in the request');
        System.assertEquals(String.valueOf(request.get('answer')), answer.Answer__c, 'The answer value should be the property included in the request');
        System.assertEquals(question.Id, answer.Question__c, 'The question relationship should be the property included in the request');
        System.assertEquals(registration.Id, answer.Registration__c, 'The registration relationship should be the property included in the request');
    }
    
    @isTest
    static void createAnswer_linkedToCampaign() {
        Question__c question = frQuestionTest.getTestQuestion();
        insert question;
        
        Campaign campaign = frCampaignTest.getTestCampaign();
        
        String funraiseId = '25';
        Map<String, Object> request = getTestRequest();
        request.put('id', funraiseId);
        request.put('questionId', question.fr_Id__c);
        request.put('pageGoalId', campaign.fr_Id__c);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/custom-question-answer';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(Json.serialize(request));
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        
        frWSCustomQuestionAnswerController.syncEntity();
        
        Test.stopTest();
        frTestUtil.assertNoErrors();
        Answer__c answer = [SELECT Id, fr_ID__c, Answer__c, Question__c, Campaign_Page__c
                            FROM Answer__c WHERE fr_ID__c = :funraiseId];
        
        System.assertEquals(String.valueOf(request.get('id')), answer.fr_Id__c, 'The ansswer id should be the property included in the request');
        System.assertEquals(String.valueOf(request.get('answer')), answer.Answer__c, 'The answer value should be the property included in the request');
        System.assertEquals(question.Id, answer.Question__c, 'The question relationship should be the property included in the request');
        System.assertEquals(campaign.Id, answer.Campaign_Page__c, 'The campaign relationship should be the property included in the request');
    }
    
    @isTest
    static void updateAnswer() {
        List<SObject> setupRecords = new List<SObject>();
        Question__c question = frQuestionTest.getTestQuestion();
        setupRecords.add(question);
        
        Opportunity opp = frDonationTest.getTestOpp();
        setupRecords.add(opp);
        insert setupRecords;
        
        String funraiseId = '25';
        Answer__c existingAnswer = new Answer__c(
        	Question__c = question.Id,
            Answer__c = 'Test Answer',
            Transaction__c = opp.Id,
            fr_Id__c = funraiseId
        );
        insert existingAnswer;
        
        String updatedAnswer = 'Updated answer';
        Map<String, Object> request = getTestRequest();
        request.put('id', funraiseId);
        request.put('questionId', question.fr_Id__c);
        request.put('donationId', opp.fr_Id__c);
        request.put('answer', updatedAnswer);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/custom-question-answer';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(Json.serialize(request));
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        
        frWSCustomQuestionAnswerController.syncEntity();
        
        Test.stopTest();
        frTestUtil.assertNoErrors();
        Answer__c answer = [SELECT Id, fr_ID__c, Answer__c, Question__c, Transaction__c
                            FROM Answer__c WHERE fr_ID__c = :funraiseId];
        
        System.assertEquals(String.valueOf(request.get('id')), answer.fr_Id__c, 'The ansswer id should be the property included in the request');
        System.assertEquals(question.Id, answer.Question__c, 'The question relationship should be the property included in the request');
        System.assertEquals(opp.Id, answer.Transaction__c, 'The transaction relationship should be the property included in the request');
        System.assertEquals(updatedAnswer, answer.Answer__c, 'The existing answer should have been updated');
        System.assertEquals(1, [SELECT COUNT() FROM Answer__c], 'There should not have been another answer created in an update');
    }
    
    @isTest
    static void deleteAnswer() {
        List<SObject> setupRecords = new List<SObject>();
        Question__c question = frQuestionTest.getTestQuestion();
        setupRecords.add(question);
        
        Opportunity opp = frDonationTest.getTestOpp();
        setupRecords.add(opp);
        insert setupRecords;
        
        String funraiseId = '25';
        Answer__c existingAnswer = new Answer__c(
        	Question__c = question.Id,
            Answer__c = 'Test Answer',
            Transaction__c = opp.Id,
            fr_Id__c = funraiseId
        );
        insert existingAnswer;
        
        Map<String, Object> request = getTestRequest();
        request.put('id', funraiseId);
        request.put('questionId', question.fr_Id__c);
        request.put('donationId', opp.fr_Id__c);
		request.put('deleted', true);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/custom-question-answer';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(Json.serialize(request));
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        
        frWSCustomQuestionAnswerController.syncEntity();
        
        Test.stopTest();
        frTestUtil.assertNoErrors();
        
        System.assertEquals(0, [SELECT COUNT() FROM Answer__c], 'The only existing answer should have been deleted');
    }
    
    @isTest
    static void createAnswer_missingQuestion() {
        //When the referenced question is missing
        //the answer should not be created and an error logged
        String funraiseId = '25';
        Map<String, Object> request = getTestRequest();
        request.put('id', funraiseId);
        request.put('questionId', 'nonexistent');
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/custom-question-answer';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(Json.serialize(request));
        RestContext.request = req;
        RestContext.response = res;
        frTestUtil.assertNoErrors();
        Test.startTest();
        
        frWSCustomQuestionAnswerController.syncEntity();
        
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM Answer__c], 'Since the question relationship was missing, the answer should not have been created');
        System.assertEquals(1, [SELECT COUNT() FROM Sync_Attempt__c], 'A sync attempt should have been generated because of the missing question');   
    }
    
    @isTest
    static void createAnswer_missingAllOptionalRelationships() {
        Question__c question = frQuestionTest.getTestQuestion();
        insert question;
        
        String funraiseId = '25';
        String badIdValue = 'nonexistent';
        Map<String, Object> request = getTestRequest();
        request.put('id', funraiseId);
        request.put('questionId', question.fr_Id__c);
        request.put('supporterId', badIdValue);
        request.put('donationId', badIdValue);
        request.put('pageGoalId', badIdValue);
        request.put('registrationId', badIdValue);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/custom-question-answer';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(Json.serialize(request));
        RestContext.request = req;
        RestContext.response = res;
        frTestUtil.assertNoErrors();
        Test.startTest();
        
        frWSCustomQuestionAnswerController.syncEntity();
        
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM Answer__c], 'The required values were provided so the answer should exist');
    }
    
    public static Map<String, Object> getTestRequest() {
        Map<String, Object> request = new Map<String, Object>();
        request.put('id', 1234);
        request.put('answer', 'Test answer');
        request.put('deleted', false);
        return request;
    }
}