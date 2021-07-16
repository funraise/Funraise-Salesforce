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
public class frQuestionTest {
    @isTest
    static void createQuestion() {
        String funraiseId = '25';
        Map<String, Object> request = getTestRequest();
        request.put('id', funraiseId);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/custom-question';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(Json.serialize(request));
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        
        frWSCustomQuestionController.syncEntity();
        
        Test.stopTest();
        frTestUtil.assertNoErrors();
        Question__c question = [SELECT Id, fr_ID__c, Name__c, Description__c, Type__c
                                FROM Question__c WHERE fr_ID__c = :funraiseId];
        
        System.assertEquals(String.valueOf(request.get('id')), question.fr_Id__c, 'The question id should be the property included in the request');
        System.assertEquals(String.valueOf(request.get('name')), question.Name__c, 'The question name should be the property included in the request');
        System.assertEquals(String.valueOf(request.get('description')), question.Description__c, 'The question description should be the property included in the request');
        System.assertEquals(String.valueOf(request.get('questionType')), question.Type__c, 'The question type should be the property included in the request');
    }
    
    @isTest
    static void updateQuestion() {
        String funraiseId = '25';
        Question__c existingQuestion = new Question__c(
        	fr_Id__c = funraiseId
        );
        insert existingQuestion;
        
        Map<String, Object> request = getTestRequest();
        request.put('id', funraiseId);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/custom-question';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(Json.serialize(request));
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        
        frWSCustomQuestionController.syncEntity();
        
        Test.stopTest();
        frTestUtil.assertNoErrors();
        Question__c question = [SELECT Id, fr_ID__c, Name__c, Description__c, Type__c
                                FROM Question__c WHERE fr_ID__c = :funraiseId];
        
        System.assertEquals(String.valueOf(request.get('id')), question.fr_Id__c, 'The question id should be the property included in the request');
        System.assertEquals(String.valueOf(request.get('name')), question.Name__c, 'The question name should be the property included in the request');
        System.assertEquals(String.valueOf(request.get('description')), question.Description__c, 'The question description should be the property included in the request');
        System.assertEquals(String.valueOf(request.get('questionType')), question.Type__c, 'The question type should be the property included in the request');
        System.assertEquals([SELECT COUNT() FROM Question__c], 1, 'A second question should not have been created');
    }
    
    @isTest
    static void deleteQuestion() {
        String funraiseId = '25';
        Question__c existingQuestion = new Question__c(
        	fr_Id__c = funraiseId,
            Name__c = 'Test Name',
            Description__c = 'Test Description',
            Type__c = 'text'
        );
        insert existingQuestion;

        Map<String, Object> request = getTestRequest();
        request.put('id', funraiseId);
        request.put('deleted', true);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/custom-question';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(Json.serialize(request));
        RestContext.request = req;
        RestContext.response = res;
        
        Integer countBefore = [SELECT COUNT() FROM Question__c];
        
        Test.startTest();
        
        frWSCustomQuestionController.syncEntity();
        
        Test.stopTest();
        frTestUtil.assertNoErrors();
        Integer countAfter = [SELECT COUNT() FROM Question__c];
        
        System.assertEquals(countBefore, 1, 'There should be one existing question before the sync');
        System.assertEquals(countAfter, 0, 'The question should have been deleted');
    }
    
    public static Map<String, Object> getTestRequest() {
        Map<String, Object> request = new Map<String, Object>();
        request.put('id', 1234);
        request.put('name', 'Test Question');
        request.put('description', 'Test Question Description');
        request.put('questionType', 'text');
        request.put('deleted', false);
        return request;
    }
    
    public static Question__c getTestQuestion() {
        return new Question__c(
            fr_Id__c = '1234',
            Name__c = 'Test Name',
            Description__c = 'Test Description',
            Type__c = 'text'
        );
    }
}