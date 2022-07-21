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
 * CREATED: 2018 Funraise Inc - https://funraise.io
 * AUTHOR: Jordan Speer
 */
@isTest
public class frCampaignTest {  
    private static String topLevelGoalId = '13';
    private static String parentGoalId = '15';
    private static String grandchildGoalId1 = '25';
    private static String grandchildGoalId2 = '39';
    
    static testMethod void createTopLevelCampaign_test() {	
        String goalId = '10';
        String campaignName = 'New Campaign';
        Map<String, Object> request = getTestRequest();
        request.put('goalId', goalId);
        
        frTestUtil.createTestPost(request);
        
        Test.startTest();
        frWSCampaignController.syncEntity();
        Test.stopTest();
        
        Campaign newCampaign = [SELECT Id, fr_ID__c, Name FROM Campaign WHERE fr_ID__c = :goalId];
        System.assertEquals(campaignName, newCampaign.Name, 'The campaign name was not correct');
    }
    
    static testMethod void createChildCampaign_test() {	
        String parentGoalId = '13';
        String parentCampaignName = 'Parent Campaign';
        String childCampaignName = 'Child campaign';
        String childGoalId = '19';
        
        Campaign parentCampaign = getTestCampaign();
        parentCampaign.fr_Id__c = parentGoalId;
        update parentCampaign;
        
        Map<String, Object> request = getTestRequest();
        request.put('name', childCampaignName);
        request.put('parentGoalId', parentGoalId);
        request.put('goalId', childGoalId);
        
        frTestUtil.createTestPost(request);
        
        Test.startTest();
        frWSCampaignController.syncEntity();
        Test.stopTest();
        
        Campaign childCampaign = [SELECT Id, fr_ID__c, Name, ParentId FROM Campaign WHERE fr_ID__c = :childGoalId];
        System.assertEquals(childCampaignName, childCampaign.Name, 'The campaign name was not correct');
        System.assertEquals(parentCampaign.Id, childCampaign.ParentId, 'The campaign parentId was not correct');
    }
    
    static testMethod void createChildCampaign_missingParent() {	
        String childCampaignName = 'Child campaign';
        String childGoalId = '19';
        
        Map<String, Object> childRequest = getTestRequest();
        childRequest.put('name', childCampaignName);
        childRequest.put('parentGoalId', parentGoalId);
        childRequest.put('goalId', childGoalId);
        
        frTestUtil.createTestPost(childRequest);
        
        Test.startTest();
        frWSCampaignController.syncEntity();
        Test.stopTest();
        
        List<Campaign> childCampaigns = [SELECT Id, fr_ID__c, Name, ParentId FROM Campaign WHERE fr_ID__c = :childGoalId];
        System.assertEquals(1, childCampaigns.size(), 'The campaign should have been created even though its parent could not be found');
        Campaign childCampaign = childCampaigns.get(0);
        System.assertEquals(childCampaignName, childCampaign.Name, 'The campaign name was not correct');
        System.assertEquals(null, childCampaign.ParentId, 'The campaign should not have a parent since the referenced id did not exist');
    }
    
    static testMethod void testDelete_missingRecord() {
        Map<String, Object> request = getTestRequest();
        request.put('parentGoalId', null);
        request.put('goalId', topLevelGoalId);
        request.put('deleted', true);
        
        frTestUtil.createTestPost(request);
        
        Test.startTest();
        frWSCampaignController.syncEntity();
        Test.stopTest();
        
        List<Campaign> campaigns = [SELECT Id, ParentId, Parent.fr_ID__c FROM Campaign];
        System.assertEquals(0, campaigns.size(), 'No exceptions should have been thrown and no data created for trying to delete a record that didnt exist');
    }
    
    static testMethod void testDeleteTopLevel() {
        createCampaigns();
        
        Map<String, Object> request = getTestRequest();
        request.put('parentGoalId', null);
        request.put('goalId', topLevelGoalId);
        request.put('deleted', true);
        
        frTestUtil.createTestPost(request);
        
        Test.startTest();
        frWSCampaignController.syncEntity();
        Test.stopTest();
        
        List<Campaign> campaigns = [SELECT Id, ParentId, Parent.fr_ID__c FROM Campaign];
        for(Campaign campaign : campaigns) {
            System.assert(campaign.Parent.fr_ID__c != topLevelGoalId, 'There should not be any campaigns referencing the deleted campaign');
        }
    }
    
    static testMethod void testDeleteParent() {
        createCampaigns();
        
        Map<String, Object> request = getTestRequest();
        request.put('parentGoalId', topLevelGoalId);
        request.put('goalId', parentGoalId);
        request.put('deleted', true);
        
        frTestUtil.createTestPost(request);
        
        Test.startTest();
        frWSCampaignController.syncEntity();
        Test.stopTest();
        
        Campaign topLevelCampaign = [SELECT Id, fr_ID__c FROM Campaign WHERE fr_ID__c = :topLevelGoalId];
        Campaign childCampaign = [SELECT Id, fr_ID__c, Name, ParentId FROM Campaign WHERE fr_ID__c = :grandchildGoalId1];
        System.assertEquals(childCampaign.ParentId, topLevelCampaign.Id, 'Parent GoalId is not correct');
        Campaign childCampaign2 = [SELECT Id, fr_ID__c, Name, ParentId FROM Campaign WHERE fr_ID__c = :grandchildGoalId2];
        System.assertEquals(childCampaign2.ParentId, topLevelCampaign.Id, 'Parent GoalId is not correct');
    }
    
    static testMethod void testDeleteGrandChild() {
        createCampaigns();
        
        Map<String, Object> request = getTestRequest();
        request.put('parentGoalId', parentGoalId);
        request.put('goalId', grandchildGoalId2);
        request.put('deleted', true);
        
        Campaign parentCampaign = [SELECT Id, fr_ID__c FROM Campaign WHERE fr_ID__c = :parentGoalId];
        List<Campaign> childCampaigns = [SELECT Id, fr_ID__c, Name, ParentId FROM Campaign WHERE parentId = :parentCampaign.Id];
        System.assertEquals(childCampaigns.size(), 2, 'Number of children is incorrect');
        
        frTestUtil.createTestPost(request);
        
        Test.startTest();
        frWSCampaignController.syncEntity();
        Test.stopTest();
        
        childCampaigns = [SELECT Id, fr_ID__c, Name, ParentId FROM Campaign WHERE parentId = :parentCampaign.Id];
        System.assertEquals(childCampaigns.size(), 1, 'Number of children is incorrect');
    }
    
    static testMethod void testUpdateCampaign() {
        createCampaigns();
        
        String updatedName = 'Grandchild Campaign';
        String updatedReason = 'The campaign is bold';
        Decimal updatedGoal = 899;
        
        Map<String, Object> request = getTestRequest();
        request.put('name', updatedName);
        request.put('reason', updatedReason);
        request.put('goalAmount', updatedGoal);
        request.put('parentGoalId', parentGoalId);
        request.put('goalId', grandchildGoalId2);
        
        frTestUtil.createTestPost(request);
        
        Test.startTest();
        frWSCampaignController.syncEntity();
        Test.stopTest();
        
        Campaign campaign = [SELECT Id, fr_ID__c, Name, Description, ExpectedRevenue FROM Campaign WHERE fr_ID__c = :grandchildGoalId2];
        System.assertEquals(campaign.Name, updatedName, 'Name was not updated');
        System.assertEquals(campaign.Description, updatedReason, 'Description was not updated');
        System.assertEquals(campaign.ExpectedRevenue, updatedGoal, 'Goal was not updated');
    }
    
    static testMethod void testCampaignMember() {
        Contact fundraiser = frDonorTest.getTestContact();
        
        String goalId = '10';
        String campaignName = 'New Campaign';
        Map<String, Object> request = getTestRequest();
        request.put('name', campaignName);
        request.put('parentGoalId', null);
        request.put('supporterId', fundraiser.fr_Id__c);
        request.put('goalId', goalId);
        
        frTestUtil.createTestPost(request);
        
        Test.startTest();
        Integer startingErrors = [SELECT COUNT() FROM Error__c];
        frWSCampaignController.syncEntity();
        
        //the same request twice shouldn't duplicate campaign members
        frWSCampaignController.syncEntity();
        Integer afterErrors = [SELECT COUNT() FROM Error__c];
        Test.stopTest();
        
        Campaign newCampaign = [SELECT Id, fr_ID__c, Name FROM Campaign WHERE fr_ID__c = :goalId];
        System.assertEquals(campaignName, newCampaign.Name, 'The campaign name was not correct');
        
        List<CampaignMember> members = [SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE CampaignId = :newCampaign.Id];
        System.assertEquals(1, members.size(), 'There should be a CampaignMember for the Fundraiser');
        CampaignMember fundraiserMember = members.get(0);
        System.assertEquals(fundraiser.Id, fundraiserMember.ContactId, 'There should be a CampaignMember for the Fundraiser');
        System.assertEquals(startingErrors, afterErrors, 'No errors were expected, even in the case of duplicate requests');
    }
    
    static void createCampaigns() {
        Campaign topLevelCampaign = new Campaign(
            Name = 'Top level Campaign',
            Description = 'The campaign is old',
            Status = 'Published',
            ExpectedRevenue = 238329.12,
            fr_Id__c = topLevelGoalId
        );
        insert topLevelCampaign;
        
        Campaign childCampaign = new Campaign(
            Name = 'Second Level Campaign',
            Description = 'The campaign is new',
            Status = 'Published',
            ExpectedRevenue = 1200,
            fr_Id__c = parentGoalId,
            ParentId = topLevelCampaign.Id
        );
        insert childCampaign;
        
        Campaign grandchildCampaign1 = new Campaign(
            Name = 'Child campaign 1',
            Description = 'The campaign is newer',
            Status = 'Published',
            ExpectedRevenue = 232,
            fr_Id__c = grandchildGoalId1,
            ParentId = childCampaign.Id
        );
        
        Campaign grandchildCampaign2 = new Campaign(
            Name = 'Child campaign 2',
            Description = 'The campaign is newest',
            Status = 'Published',
            ExpectedRevenue = 452,
            fr_Id__c = grandchildGoalId2,
            ParentId = childCampaign.Id
        );
        insert new List<Campaign>{grandchildCampaign1, grandchildCampaign2};
    }
    
    public static Campaign getTestCampaign() {
        Campaign campaign = new Campaign();
        campaign.Name = 'Test Campaign';
        campaign.Description = 'Test Campaign Description';
        campaign.Status = 'Published';
        campaign.ExpectedRevenue = 1000;
        campaign.fr_ID__c = '19920602';
        insert campaign;
        return campaign;
    }
    
    public static Map<String, Object> getTestRequest() {
        Map<String, Object> request = new Map<String, Object>();
        request.put('name', 'New Campaign');
        request.put('reason', 'The campaign is new');
        request.put('status', 'Published');
        request.put('goalAmount', '238329.12');
        request.put('parentGoalId', null);
        request.put('deleted', false);
        return request;
    }
}