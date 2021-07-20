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
    static testMethod void syncEntity_task() {
        Contact supporter = new Contact(LastName = 'Test', FirstName = 'Existing', Email = 'testExisting@example.com', fr_ID__c = '410');
		Opportunity donation = new Opportunity(fr_ID__c = '67', StageName = 'Closed Won', Name = 'donation1', CloseDate = Date.today());
        Opportunity unrelatedDonation = new Opportunity(fr_ID__c = '68', StageName = 'Closed Won', Name = 'donation2', CloseDate = Date.today());
        insert new List<SObject>{supporter, donation, unrelatedDonation};
        
        frTestUtil.createTestPost(getTestRequest());
        Test.startTest();
        frWSTaskController.syncEntity();
        Test.stopTest();
        
        List<Task> expectedTasks = [SELECT Id, WhoId, WhatId FROM Task WHERE fr_Task_ID__c = '856'];
        System.assertEquals(1, expectedTasks.size(), 'An unexpected number of tasks were returned');
        Task expectedTask = expectedTasks.get(0);
        System.assertEquals(expectedTask.WhoId, supporter.Id, 'The task was not related to the correct supporter');
        System.assertEquals(expectedTask.WhatId, donation.Id, 'The task was not related to the correct opportunity');
    }
    
    static testMethod void syncEntity_interaction() {
        Contact supporter = new Contact(LastName = 'Test', FirstName = 'Existing', Email = 'testExisting@example.com', fr_ID__c = '410');
        insert supporter;
        
        Map<String, Object> request = getTestRequest();
        request.put('taskType', 'Interaction');
        request.remove('donationId');
        
        frTestUtil.createTestPost(request);
        Test.startTest();
        frWSTaskController.syncEntity();
        Test.stopTest();
        
        List<Task> expectedTasks = [SELECT Id, WhoId, WhatId FROM Task WHERE fr_Task_ID__c = '856'];
        System.assertEquals(1, expectedTasks.size(), 'An unexpected number of tasks were returned');
        Task expectedTask = expectedTasks.get(0);
        System.assertEquals(expectedTask.WhoId, supporter.Id, 'The interaction was not related to the correct supporter');
    }

    static testMethod void syncEntity_missingSupporter() {
        frTestUtil.createTestPost(getTestRequest());
        Test.startTest();
        frWSTaskController.syncEntity();
        Test.stopTest();
        
        Integer resultingTasks = [SELECT COUNT() FROM Task WHERE fr_Task_ID__c != null];
        System.assertEquals(0, resultingTasks, 'A task should not have been created if the supporter/contact could not be found');
    }
    
    static testMethod void syncEntity_testDelete() {
        Contact supporter = new Contact(LastName = 'Test', FirstName = 'Existing', Email = 'testExisting@example.com', fr_ID__c = '410');
		Opportunity donation = new Opportunity(fr_ID__c = '67', StageName = 'Closed Won', Name = 'donation1', CloseDate = Date.today());
        insert new List<SObject>{supporter, donation};
            
        Task existingTask = new Task(fr_Task_Id__c = '856', Description = 'Test Task', Priority = 'Normal', WhoId = supporter.Id,
                                    WhatId = donation.Id);
        insert existingTask;

        Map<String, Object> request = getTestRequest();
        request.put('deleted', true);
        
        frTestUtil.createTestPost(request);
        Test.startTest();
        frWSTaskController.syncEntity();
        Test.stopTest();
        
        Integer expectedTasks = [SELECT COUNT() FROM Task WHERE fr_Task_ID__c = :existingTask.fr_Task_Id__c];
        System.assertEquals(0, expectedTasks, 'The task should have been deleted');
    }
    
    
    
    static testMethod void syncEntity_testDelete_notFound() {
        Contact supporter = new Contact(LastName = 'Test', FirstName = 'Existing', Email = 'testExisting@example.com', fr_ID__c = '410');
		Opportunity donation = new Opportunity(fr_ID__c = '67', StageName = 'Closed Won', Name = 'donation1', CloseDate = Date.today());
        insert new List<SObject>{supporter, donation};
            
        Task existingTask = new Task(fr_Task_Id__c = '111', Description = 'Test Task', Priority = 'Normal', WhoId = supporter.Id,
                                    WhatId = donation.Id);
        insert existingTask;

        Map<String, Object> request = getTestRequest();
        request.put('id', 222); //different from existing, won't be found. nothing should be deleted
        request.put('deleted', true);
        
        frTestUtil.createTestPost(request);
        Test.startTest();
        frWSTaskController.syncEntity();
        Test.stopTest();
        
        Integer expectedTasks = [SELECT COUNT() FROM Task WHERE fr_Task_ID__c = :existingTask.fr_Task_Id__c];
        System.assertEquals(1, expectedTasks, 'The existing task should NOT have been deleted');
    }
    
    public static Map<String, Object> getTestRequest() {
        Map<String, Object> request = new Map<String, Object>();
        request.put('id', 856);
        request.put('status', 'Pending');
        request.put('donationId', 67);
        request.put('donorId', 410);
        request.put('description', 'Test description');
        request.put('taskType', 'Activity');
        request.put('createdDate', 1493077510493L);
        request.put('updtime', 1487801043934L);
        request.put('completedDate', 1487801043597L);
        request.put('deleted', false);
        return request;
    }
}