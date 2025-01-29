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
public class frSubscriptionTest {

    //
    // 1) createSubscription_noCampaign
    //
    static testMethod void createSubscription_noCampaign() {
        if (frUtil.hasNPCobjects()) {
            return;
        }

        Contact testSupporter = frDonorTest.getTestContact();
                
        String funraiseId = '25';
        Map<String, Object> request = getTestRequest();
        request.put('supporterId', testSupporter.fr_ID__c);
        request.put('id', funraiseId);

        frTestUtil.createTestPost(request);
        
        Test.startTest();
        frWSSubscriptionController.syncEntity();
        Test.stopTest();
        
        Subscription__c subscription = [SELECT Id, fr_ID__c, 
                                        Name, Allocation_Name__c, 
                                        Amount__c, Campaign_Page_Name__c, Comment__c, 
                                        Company_Match__c, Company_Match_Company_Name__c, 
                                        Company_Match_Employee_Email__c, Currency__c, Dedication__c, 
                                        Dedication_Email__c, Dedication_Message__c, Dedication_Name__c, 
                                        Dedication_Type__c, Form_Name__c, Frequency__c, 
                                        Campaign_Goal__c, Imported__c, Next_Payment_Date__c, 
                                        Note__c, Operations_Tip__c, Payment_Method_Expiration_Date__c, Payment_Method_Last_Four__c, 
                                        Payment_Method_Type__c, Status__c, Supporter__c
        FROM Subscription__c WHERE fr_ID__c = :funraiseId];
        System.assertEquals(String.valueOf(request.get('name')), subscription.Name, 'The subscription name should be the property included in the request');
        System.assertEquals(String.valueOf(request.get('allocationName')), subscription.Allocation_Name__c, 'The property should be what was provided in the request');
        System.assertEquals(Double.valueOf(request.get('amount')), subscription.Amount__c, 'The property should be what was provided in the request');
        System.assertEquals(String.valueOf(request.get('campaignPageName')), subscription.Campaign_Page_Name__c, 'The property should be what was provided in the request');
        System.assertEquals(String.valueOf(request.get('comment')), subscription.Comment__c, 'The property should be what was provided in the request');
        System.assertEquals(Boolean.valueOf(request.get('companyMatch')), subscription.Company_Match__c, 'The property should be what was provided in the request');
        System.assertEquals(String.valueOf(request.get('companyMatchCompanyName')), subscription.Company_Match_Company_Name__c, 'The property should be what was provided in the request');
        System.assertEquals(String.valueOf(request.get('companyMatchEmployeeEmail')), subscription.Company_Match_Employee_Email__c, 'The property should be what was provided in the request');
        System.assertEquals(String.valueOf(request.get('currency')), subscription.Currency__c, 'The property should be what was provided in the request');
        System.assertEquals(Boolean.valueOf(request.get('dedication')), subscription.Dedication__c, 'The property should be what was provided in the request');
        System.assertEquals(String.valueOf(request.get('dedicationEmail')), subscription.Dedication_Email__c, 'The property should be what was provided in the request');
        System.assertEquals(String.valueOf(request.get('dedicationMessage')), subscription.Dedication_Message__c, 'The property should be what was provided in the request');
        System.assertEquals(String.valueOf(request.get('dedicationName')), subscription.Dedication_Name__c, 'The property should be what was provided in the request');
        System.assertEquals(String.valueOf(request.get('dedicationType')), subscription.Dedication_Type__c, 'The property should be what was provided in the request');
        System.assertEquals(String.valueOf(request.get('formName')), subscription.Form_Name__c, 'The property should be what was provided in the request');
        System.assertEquals(String.valueOf(request.get('frequency')), subscription.Frequency__c, 'The property should be what was provided in the request');
        System.assertEquals(Boolean.valueOf(request.get('imported')), subscription.Imported__c, 'The property should be what was provided in the request');
        System.assertEquals(String.valueOf(request.get('note')), subscription.Note__c, 'The property should be what was provided in the request');
        System.assertEquals(Boolean.valueOf(request.get('operationsTip')), subscription.Operations_Tip__c, 'The property should be what was provided in the request');
        System.assertEquals(String.valueOf(request.get('paymentMethodExpirationDate')), subscription.Payment_Method_Expiration_Date__c, 'The property should be what was provided in the request');
        System.assertEquals(String.valueOf(request.get('paymentMethodLastFour')), subscription.Payment_Method_Last_Four__c, 'The property should be what was provided in the request');
        System.assertEquals(String.valueOf(request.get('paymentMethodType')), subscription.Payment_Method_Type__c, 'The property should be what was provided in the request');
        System.assertEquals(String.valueOf(request.get('status')), subscription.Status__c, 'The property should be what was provided in the request');
        List<Object> requestPaymentDate = (List<Object>)request.get('nextPaymentDate');
        System.assertEquals(frModel.convertFromLocalDate(requestPaymentDate), subscription.Next_Payment_Date__c, 'The property for next payment date should be what was provided in the request');
        
        System.assertEquals(testSupporter.Id, subscription.Supporter__c, 'The lookup for supporter should have been populated with the contact that has the funraise id referenced in the request');
        System.assertEquals(0, [SELECT COUNT() FROM Error__c], 'No errors were expected');
    }

    static testMethod void createSubscription_noCampaign_NPC() {
        if (!frUtil.hasNPCobjects()) {
            return;
        }
        Contact testSupporter = frDonorTest.getTestContact();
        Account testAccount = frDonorTest.getTestAccount(true);
                
        String funraiseId = '25';
        Map<String, Object> request = getTestRequest();
        request.put('supporterId', testSupporter.fr_ID__c);
        request.put('id', funraiseId);

        if(frUtil.hasNPCobjects()) request.put('supporterId', testAccount.fr_ID__c);

        frTestUtil.createTestPost(request);
        
        Test.startTest();
        frWSSubscriptionController.syncEntity();
        Test.stopTest();

        List<SObject> gcList = Database.query(
            'SELECT Id, Name, DonorId ' +
            'FROM GiftCommitment ' +
            'WHERE fr_ID__c = :funraiseId'
        );

        System.assertEquals(String.valueOf(request.get('name')), gcList[0].get('Name'));
        System.assertEquals(testAccount.Id, gcList[0].get('DonorId'));
        System.assertEquals(0, [SELECT COUNT() FROM Error__c]);
    }

    //
    // 2) createSubscription_withCampaignGoal
    //
    static testMethod void createSubscription_withCampaignGoal() {	
        Contact testSupporter = frDonorTest.getTestContact();
        
        Campaign testCampaign = new Campaign(fr_ID__c = '10', Name = 'Test Campaign', 
                                             ExpectedRevenue = 123, Description = 'Test', Status = 'Published');
        insert testCampaign;
        
        String funraiseId = '25';
        Map<String, Object> request = getTestRequest();
        request.put('supporterId', testSupporter.fr_ID__c);
        request.put('id', funraiseId);
        request.put('campaignGoalId', testCampaign.fr_ID__c);
        
        frTestUtil.createTestPost(request);

        Test.startTest();
        frWSSubscriptionController.syncEntity();
        Test.stopTest();

        Subscription__c subscription = [SELECT Id, fr_ID__c, Campaign_Goal__c FROM Subscription__c WHERE fr_ID__c = :funraiseId];
        System.assertEquals(testCampaign.Id, subscription.Campaign_Goal__c, 'The subscription should have been assocaited with the campaign goal included in the request');
        frTestUtil.assertNoErrors();
    }

    static testMethod void createSubscription_withCampaignGoal_NPC() {
        if (!frUtil.hasNPCobjects()) {
            return;
        }
        Account testAccount = frDonorTest.getTestAccount(true);
        
        Campaign testCampaign = new Campaign(fr_ID__c = '10', Name = 'Test Campaign', 
                                             ExpectedRevenue = 123, Description = 'Test', Status = 'Published');
        insert testCampaign;
        
        String funraiseId = '25';
        Map<String, Object> request = getTestRequest();
        request.put('id', funraiseId);
        request.put('campaignGoalId', testCampaign.fr_ID__c);
        request.put('supporterId', testAccount.fr_ID__c);
        frTestUtil.createTestPost(request);

        Test.startTest();
        frWSSubscriptionController.syncEntity();
        Test.stopTest();

        List<SObject> gcList = Database.query(
            'SELECT Id, Name, CampaignId ' +
            'FROM GiftCommitment ' +
            'WHERE fr_ID__c = :funraiseId'
        );
        System.assertEquals(testCampaign.Id, gcList[0].get('CampaignId'));
        frTestUtil.assertNoErrors();
    }

    //
    // 3) createSubscription_missingSupporter
    //
    static testMethod void createSubscription_missingSupporter() {	
        Contact testSupporter = frDonorTest.getTestContact();
        
        String funraiseId = '25';
        Map<String, Object> request = getTestRequest();
        request.put('supporterId', testSupporter.fr_ID__c+'1');
        request.put('id', funraiseId);

        frTestUtil.createTestPost(request);
        
        Test.startTest();
        frWSSubscriptionController.syncEntity();
        Test.stopTest();

        Integer subscriptions = [SELECT COUNT() FROM Subscription__c WHERE fr_ID__c = :funraiseId];
        System.assertEquals(0, subscriptions, 'Since the supporter could not be found, the subscription should not have been created');
        System.assertEquals(1, [SELECT COUNT() FROM Sync_Attempt__c], 'There should be a sync attempt to retry the failed sync');
    }

    static testMethod void createSubscription_missingSupporter_NPC() {
        if (!frUtil.hasNPCobjects()) {
            return;
        }
        Contact testSupporter = frDonorTest.getTestContact();
        Account testAccount = frDonorTest.getTestAccount(true);
        testAccount.put('fr_ID__c', '123456');
        update testAccount;

        String funraiseId = '25';
        Map<String, Object> request = getTestRequest();
        request.put('supporterId', testAccount.fr_ID__c + '1');
        request.put('id', funraiseId);

        frTestUtil.createTestPost(request);

        Test.startTest();
        frWSSubscriptionController.syncEntity();
        Test.stopTest();

        List<SObject> gcList = Database.query('SELECT Id, Name FROM GiftCommitment WHERE fr_ID__c = :funraiseId');
        System.assertEquals(0, gcList.size(), 'Should not create GiftCommitment when supporter is missing');
        System.assertEquals(1, [SELECT COUNT() FROM Sync_Attempt__c]);
    }

    //
    // 4) createSubscription_missingCampaignGoal
    //
    static testMethod void createSubscription_missingCampaignGoal() {	
        Contact testSupporter = frDonorTest.getTestContact();
        
        Campaign testCampaign = new Campaign(fr_ID__c = '10', Name = 'Test Campaign', 
                                             ExpectedRevenue = 123, Description = 'Test', Status = 'Published');
        insert testCampaign;
        
        String funraiseId = '25';
        Map<String, Object> request = getTestRequest();
        request.put('supporterId', testSupporter.fr_ID__c);
        request.put('id', funraiseId);
        request.put('campaignGoalId', testCampaign.fr_ID__c+'1');

        frTestUtil.createTestPost(request);
        
        Test.startTest();
        frWSSubscriptionController.syncEntity();
        Test.stopTest();

        Subscription__c subscription = [SELECT Id, fr_ID__c, Campaign_Goal__c FROM Subscription__c WHERE fr_ID__c = :funraiseId];
        System.assertEquals(null, subscription.Campaign_Goal__c, 'The subscription should not have been associated with a campaign since the requested id does not exist');
    }

    static testMethod void createSubscription_missingCampaignGoal_NPC() {
        if (!frUtil.hasNPCobjects()) {
            return;
        }
        Contact testSupporter = frDonorTest.getTestContact();
        Account testAccount = frDonorTest.getTestAccount(true);
        
        Campaign testCampaign = new Campaign(fr_ID__c = '10', Name = 'Test Campaign', 
                                             ExpectedRevenue = 123, Description = 'Test', Status = 'Published');
        insert testCampaign;
        
        String funraiseId = '25';
        Map<String, Object> request = getTestRequest();
        request.put('supporterId', testSupporter.fr_ID__c);
        request.put('id', funraiseId);
        request.put('campaignGoalId', testCampaign.fr_ID__c+'1');
        if(frUtil.hasNPCobjects()) request.put('supporterId', testAccount.fr_ID__c);

        frTestUtil.createTestPost(request);
        
        Test.startTest();
        frWSSubscriptionController.syncEntity();
        Test.stopTest();
        List<SObject> gcList = Database.query(
            'SELECT Id, Name, CampaignId ' +
            'FROM GiftCommitment '
        );
        System.assertEquals(null, gcList[0].get('CampaignId'));
    }

    //
    // 5) deleteSubscription
    //
    static testMethod void deleteSubscription() {	      
        Contact testSupporter = frDonorTest.getTestContact();
        
        insert new Subscription__c(Name = 'Test Sub', fr_ID__c = '25', Supporter__c = testSupporter.Id);
        
        String funraiseId = '25';
        Map<String, Object> request = getTestRequest();
        request.put('supporterId', testSupporter.fr_ID__c);
        request.put('id', funraiseId);
        request.put('deleted', true);

        frTestUtil.createTestPost(request);

        Test.startTest();
        frWSSubscriptionController.syncEntity();
        Test.stopTest();

        Integer matchingRecords = [SELECT COUNT() FROM Subscription__c WHERE fr_ID__c = :funraiseId];
        System.assertEquals(0, matchingRecords, 'subscription should have been deleted and therefore not returned');
        System.assertEquals(0, [SELECT COUNT() FROM Error__c], 'No errors were expected');
    }

    static testMethod void deleteSubscription_NPC() {
        if (!frUtil.hasNPCobjects()) {
            return;
        }
        Contact testSupporter = frDonorTest.getTestContact();
        Account testAccount = frDonorTest.getTestAccount(true);
        testAccount.put('fr_ID__c', '123456');
        update testAccount;

        SObject matchingNPCRecord = Schema.getGlobalDescribe().get('giftcommitment').newSObject();
        matchingNPCRecord.put('fr_ID__c', '25');
        matchingNPCRecord.put('Name', 'Test Sub');
        matchingNPCRecord.put('DonorId', testAccount.Id);
        insert matchingNPCRecord;

        String funraiseId = '25';
        Map<String, Object> request = getTestRequest();
        request.put('supporterId', testAccount.fr_ID__c);
        request.put('id', funraiseId);
        request.put('deleted', true);

        frTestUtil.createTestPost(request);

        Test.startTest();
        frWSSubscriptionController.syncEntity();
        Test.stopTest();

        List<SObject> gcList = Database.query('SELECT Id, Name FROM GiftCommitment WHERE fr_ID__c = :funraiseId');
        System.assertEquals(0, gcList.size(), 'subscription (GiftCommitment) should have been deleted');
        System.assertEquals(0, [SELECT COUNT() FROM Error__c]);
    }

    //
    // 6) createSubscription_createPledge
    //
    static testMethod void createSubscription_createPledge() {
        Contact testSupporter = frDonorTest.getTestContact();
                
        String funraiseId = '25';
        Map<String, Object> request = getTestRequest();
        request.put('supporterId', testSupporter.fr_ID__c);
        request.put('id', funraiseId);
        request.put('pledgeAmount', 500);
        
        frTestUtil.createTestPost(request);

        Test.startTest();
        frWSSubscriptionController.syncEntity();
        Test.stopTest();
        
        Subscription__c subscription = [SELECT Id, Supporter__c FROM Subscription__c WHERE fr_ID__c = :funraiseId];
        System.assertEquals(testSupporter.Id, subscription.Supporter__c, 'The lookup for supporter should have been populated with the contact that has the funraise id referenced in the request');
        System.assertEquals(0, [SELECT COUNT() FROM Error__c], 'No errors were expected');
		Pledge__c pledge = [SELECT Id, Pledge_Amount__c, Supporter__c FROM Pledge__c WHERE Pledge_Subscription__c = :subscription.Id];
        System.assertEquals(testSupporter.Id, pledge.Supporter__c, 'The pledge should have been created with the same supporter as the subscription');
        System.assertEquals(500, pledge.Pledge_Amount__c, 'The pledge amount should have been what was received in the request');
    }

    static testMethod void createSubscription_createPledge_NPC() {
        if (!frUtil.hasNPCobjects()) {
            return;
        }
        Contact testSupporter = frDonorTest.getTestContact();
        Account testAccount = frDonorTest.getTestAccount(true);
        
        Campaign testCampaign = new Campaign(fr_ID__c = '10', Name = 'Test Campaign', 
                                             ExpectedRevenue = 123, Description = 'Test', Status = 'Published');
        insert testCampaign;
        
        String funraiseId = '25';
        Map<String, Object> request = getTestRequest();
        request.put('supporterId', testSupporter.fr_ID__c);
        request.put('id', funraiseId);
        request.put('campaignGoalId', testCampaign.fr_ID__c);
        if(frUtil.hasNPCobjects()) request.put('supporterId', testAccount.fr_ID__c);
        frTestUtil.createTestPost(request);

        Test.startTest();
        frWSSubscriptionController.syncEntity();
        Test.stopTest();
        
        List<SObject> gcList = Database.query(
            'SELECT Id, Name, DonorId ' + 
            'FROM GiftCommitment ' +
            'WHERE fr_ID__c = :funraiseId'
        );
        System.assertEquals(1, gcList.size(), 'GiftCommitment should have been created');
        System.assertEquals(testAccount.Id, gcList[0].get('DonorId'));
        System.assertEquals(0, [SELECT COUNT() FROM Error__c]);
    }

    public static Map<String, Object> getTestRequest() {
        Map<String, Object> request = new Map<String, Object>();
        request.put('name', '000001');
        request.put('status', 'Active');
        request.put('paymentMethodExpirationDate', '05/2022');
        request.put('paymentMethodType', 'Credit Card');
        request.put('paymentMethodLastFour', '1111');
        request.put('formName', 'Test Site 12041007');
        List<Object> nextPaymentDate = new List<Object> {2019, 6, 20};
        request.put('nextPaymentDate', nextPaymentDate);
        request.put('frequency', 'Monthly');
        request.put('amount', 20.6);
        request.put('currency', 'USD');
        request.put('campaignPageName', 'Test Site 12041007 homepage');
        request.put('allocationName', 'alex test alloc');
        request.put('comment', 'Test Comment');
        request.put('note', 'Test Note');
        request.put('dedication', false);
        request.put('dedicationType', 'In Honor Of');
        request.put('dedicationName', 'Martha Wayne');
        request.put('dedicationMessage', 'Miss you Mom');
        request.put('dedicationEmail', 'martha@example.com');
        request.put('companyMatch', true);
        request.put('companyMatchCompanyName', 'WayneTech');
        request.put('companyMatchEmployeeEmail', 'bruce@example.com');
        request.put('operationsTip', true);
        request.put('imported', false);
        request.put('deleted', false);
        request.put('pledgeAmount', null);
        return request;
    }
}