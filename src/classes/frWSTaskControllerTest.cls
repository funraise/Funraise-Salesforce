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
*     This product includes software developed by Funraise inc.
*  4. Neither the name of Funraise inc nor the
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
* CREATED: 9-19-2018 Funraise Inc - https://funraise.io
* AUTHOR: Mark Daniel Dufresne
*/
@isTest
public class frWSTaskControllerTest {
    static testMethod void syncEntity_test() {
        insert new Contact(LastName = 'Test', FirstName = 'Existing', Email = 'testExisting@example.com', fr_ID__c = '410');
        insert new Opportunity(fr_ID__c = '67', StageName = 'Closed Won', Name = 'donation1', CloseDate = Date.today());
        insert new Opportunity(fr_ID__c = '68', StageName = 'Closed Won', Name = 'donation2', CloseDate = Date.today());
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/task';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(getTestPayload());
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        
        frWSTaskController.syncEntity();
        
        Test.stopTest();
        
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(
            res.responseBody.toString()
        );
        
        Boolean success = (Boolean)response.get('success');
        System.assert(success, 'task update failed');
        
        String message = (String)response.get('message');
        System.assertEquals('', message, 'error message on update');
    }
    
    private static String getTestPayload() {
        
        return '{'+
                '"id":856,'+
                '"status":"Pending",'+
                '"donationId":67,'+
                '"donorId":410,'+
                '"description":"Test description",'+
                '"taskType":"Activity",'+
                '"createdDate":1493077510493,'+
                '"updtime":1487801043934,'+
                '"completedDate":1487801043597'+
            '}';
    }
}
