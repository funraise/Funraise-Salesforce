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
* CREATED: 2021 Funraise Inc - https://funraise.io
* AUTHOR: Alex Molina
*/
@isTest
public class frSyncRequestHandlerTest {
    private static void testProcess(Sync_Attempt__c attempt) {
        insert attempt;
        Test.startTest();
        frSyncRequestHandler handler = new frSyncRequestHandler();
        Database.executeBatch(handler, frSyncRequestHandler.BATCH_SIZE);
        Test.stopTest();
        
        for(Sync_Attempt__c result : [SELECT Id, Attempts__c FROM Sync_Attempt__c]) {
            System.assertEquals(2, result.Attempts__c, 'Every attempt should have recorded a new attempt to process');
        }
    }
    
    
    static testMethod void syncAnswer() {
        Sync_Attempt__c attempt = new Sync_Attempt__c(
            Request_Body__c = Json.serialize(frAnswerTest.getTestRequest()),
            Type__c = frUtil.Entity.ANSWER.name(),
            Attempts__c = 1
        );
        testProcess(attempt);
    }
    
    static testMethod void syncCampaign() {
        Sync_Attempt__c attempt = new Sync_Attempt__c(
            Request_Body__c = Json.serialize(frCampaignTest.getTestRequest()),
            Type__c = frUtil.Entity.CAMPAIGN.name(),
            Attempts__c = 1
        );
        testProcess(attempt);
    }
    
    static testMethod void syncDonation() {
        Sync_Attempt__c attempt = new Sync_Attempt__c(
            Request_Body__c = Json.serialize(frDonationTest.getTestRequest()),
            Type__c = frUtil.Entity.DONATION.name(),
            Attempts__c = 1
        );
        testProcess(attempt);
    }
    
    static testMethod void syncSupporter() {
        Sync_Attempt__c attempt = new Sync_Attempt__c(
            Request_Body__c = Json.serialize(frDonorTest.getTestRequest()),
            Type__c = frUtil.Entity.SUPPORTER.name(),
            Attempts__c = 1
        );
        testProcess(attempt);
    }
    
    static testMethod void syncEmail() {
        Sync_Attempt__c attempt = new Sync_Attempt__c(
            Request_Body__c = Json.serialize(frDonorEmailsTest.getTestRequest()),
            Type__c = frUtil.Entity.EMAIL.name(),
            Attempts__c = 1
        );
        testProcess(attempt);
    }
    
    static testMethod void syncRegistration() {
        Sync_Attempt__c attempt = new Sync_Attempt__c(
            Request_Body__c = Json.serialize(frFundraisingEventRegistrationTest.getTestRequest()),
            Type__c = frUtil.Entity.REGISTRATION.name(),
            Attempts__c = 1
        );
        testProcess(attempt);
    }
    
    static testMethod void syncEvent() {
        Sync_Attempt__c attempt = new Sync_Attempt__c(
            Request_Body__c = Json.serialize(frFundraisingEventTest.getTestRequest()),
            Type__c = frUtil.Entity.EVENT.name(),
            Attempts__c = 1
        );
        testProcess(attempt);
    }
    
    static testMethod void syncQuestion() {
        Sync_Attempt__c attempt = new Sync_Attempt__c(
            Request_Body__c = Json.serialize(frQuestionTest.getTestRequest()),
            Type__c = frUtil.Entity.QUESTION.name(),
            Attempts__c = 1
        );
        testProcess(attempt);
    }
    
    static testMethod void syncSubscription() {
        Sync_Attempt__c attempt = new Sync_Attempt__c(
            Request_Body__c = Json.serialize(frSubscriptionTest.getTestRequest()),
            Type__c = frUtil.Entity.SUBSCRIPTION.name(),
            Attempts__c = 1
        );
        testProcess(attempt);
    }
    
    static testMethod void syncTask() {
        Sync_Attempt__c attempt = new Sync_Attempt__c(
            Request_Body__c = Json.serialize(frWSTaskControllerTest.getTestRequest()),
            Type__c = frUtil.Entity.TASK.name(),
            Attempts__c = 1
        );
        testProcess(attempt);
    }
}