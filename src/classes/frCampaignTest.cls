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
    
    static String topLevelGoalId = '13';
    static String parentGoalId = '15';
    static String grandchildGoalId1 = '25';
    static String grandchildGoalId2 = '39';
    
    static testMethod void createTopLevelCampaign_test() {	
        String goalId = '10';
        String campaignName = 'New Campaign';
        Map<String, Object> request = new Map<String, Object>();
        request.put('name', 'New Campaign');
        request.put('reason', 'The campaign is new');
        request.put('status', 'Published');
        request.put('goalAmount', '238329.12');
        request.put('parentGoalId', null);
        request.put('goalId', goalId);
        request.put('deleted', false);

        Test.startTest();
        new frCampaign(request);
        Test.stopTest();

        Campaign newCampaign = [SELECT Id, fr_ID__c, Name FROM Campaign WHERE fr_ID__c = :goalId];
        System.assertEquals(campaignName, newCampaign.Name, 'The campaign name was not correct');
    }
    
    static testMethod void createChildCampaign_test() {	
        String parentGoalId = '13';
        String parentCampaignName = 'Parent Campaign';
        String childCampaignName = 'Child campaign';
        String childGoalId = '19';
        
        Map<String, Object> parentRequest = new Map<String, Object>();
        parentRequest.put('name', parentCampaignName);
        parentRequest.put('reason', 'The campaign is new');
        parentRequest.put('status', 'Published');
        parentRequest.put('goalAmount', '238329.12');
        parentRequest.put('parentGoalId', null);
        parentRequest.put('goalId', parentGoalId);
        parentRequest.put('deleted', false);
        
        Map<String, Object> childRequest = new Map<String, Object>();
        childRequest.put('name', childCampaignName);
        childRequest.put('reason', 'The campaign is new');
        childRequest.put('status', 'Published');
        childRequest.put('goalAmount', '1200');
        childRequest.put('parentGoalId', parentGoalId);
        childRequest.put('goalId', childGoalId);
        childRequest.put('deleted', false);
        
        new frCampaign(parentRequest);

        Test.startTest();
        new frCampaign(childRequest);
        Test.stopTest();

        Campaign parentCampaign = [SELECT Id, fr_ID__c FROM Campaign WHERE fr_ID__c = :parentGoalId];
        Campaign childCampaign = [SELECT Id, fr_ID__c, Name, ParentId FROM Campaign WHERE fr_ID__c = :childGoalId];
        System.assertEquals(childCampaignName, childCampaign.Name, 'The campaign name was not correct');
        System.assertEquals(parentCampaign.Id, childCampaign.ParentId, 'The campaign parentId was not correct');
    }
    
    static testMethod void createChildCampaign_missingParent() {	
        String childCampaignName = 'Child campaign';
        String childGoalId = '19';
        
        Map<String, Object> childRequest = new Map<String, Object>();
        childRequest.put('name', childCampaignName);
        childRequest.put('reason', 'The campaign is new');
        childRequest.put('status', 'Published');
        childRequest.put('goalAmount', '1200');
        childRequest.put('parentGoalId', parentGoalId);
        childRequest.put('goalId', childGoalId);
        childRequest.put('deleted', false);

        Test.startTest();
        new frCampaign(childRequest);
        Test.stopTest();

        List<Campaign> childCampaigns = [SELECT Id, fr_ID__c, Name, ParentId FROM Campaign WHERE fr_ID__c = :childGoalId];
        System.assertEquals(1, childCampaigns.size(), 'The campaign should have been created even though its parent could not be found');
        Campaign childCampaign = childCampaigns.get(0);
        System.assertEquals(childCampaignName, childCampaign.Name, 'The campaign name was not correct');
        System.assertEquals(null, childCampaign.ParentId, 'The campaign should not have a parent since the referenced id did not exist');
    }
    
    static testMethod void testDelete_missingRecord() {
        Map<String, Object> topLevelCampaign = new Map<String, Object>();
        topLevelCampaign.put('name', 'Top level Campaign');
        topLevelCampaign.put('reason', 'The campaign is old');
        topLevelCampaign.put('status', 'Published');
        topLevelCampaign.put('goalAmount', '238329.12');
        topLevelCampaign.put('parentGoalId', null);
        topLevelCampaign.put('goalId', topLevelGoalId);
        topLevelCampaign.put('deleted', true);
        
        Test.startTest();
        new frCampaign(topLevelCampaign);
        Test.stopTest();
        
        List<Campaign> campaigns = [SELECT Id, ParentId, Parent.fr_ID__c FROM Campaign];
        System.assertEquals(0, campaigns.size(), 'No exceptions should have been thrown and no data created for trying to delete a record that didnt exist');
        
    }
    
    static testMethod void testDeleteTopLevel() {
        createCampaigns();
                
        Map<String, Object> topLevelCampaign = new Map<String, Object>();
        topLevelCampaign.put('name', 'Top level Campaign');
        topLevelCampaign.put('reason', 'The campaign is old');
        topLevelCampaign.put('status', 'Published');
        topLevelCampaign.put('goalAmount', '238329.12');
        topLevelCampaign.put('parentGoalId', null);
        topLevelCampaign.put('goalId', topLevelGoalId);
        topLevelCampaign.put('deleted', true);
        
        Test.startTest();
        new frCampaign(topLevelCampaign);
        Test.stopTest();
        
        List<Campaign> campaigns = [SELECT Id, ParentId, Parent.fr_ID__c FROM Campaign];
        for(Campaign campaign : campaigns) {
            System.assert(campaign.Parent.fr_ID__c != topLevelGoalId, 'There should not be any campaigns referencing the deleted campaign');
        }
    }
    
    static testMethod void testDeleteParent() {
        createCampaigns();
                
        Map<String, Object> parentRequest = new Map<String, Object>();
        parentRequest.put('name', 'Parent Campaign');
        parentRequest.put('reason', 'The campaign is new');
        parentRequest.put('status', 'Published');
        parentRequest.put('goalAmount', '238329.12');
        parentRequest.put('parentGoalId', topLevelGoalId);
        parentRequest.put('goalId', parentGoalId);
        parentRequest.put('deleted', true);
        
        Test.startTest();
        new frCampaign(parentRequest);
        Test.stopTest();
        
        Campaign topLevelCampaign = [SELECT Id, fr_ID__c FROM Campaign WHERE fr_ID__c = :topLevelGoalId];
        Campaign childCampaign = [SELECT Id, fr_ID__c, Name, ParentId FROM Campaign WHERE fr_ID__c = :grandchildGoalId1];
        System.assertEquals(childCampaign.ParentId, topLevelCampaign.Id, 'Parent GoalId is not correct');
        Campaign childCampaign2 = [SELECT Id, fr_ID__c, Name, ParentId FROM Campaign WHERE fr_ID__c = :grandchildGoalId2];
        System.assertEquals(childCampaign2.ParentId, topLevelCampaign.Id, 'Parent GoalId is not correct');
    }
    
    static testMethod void testDeleteGrandChild() {
        createCampaigns();

        Map<String, Object> grandchildCampaign2 = new Map<String, Object>();
        grandchildCampaign2.put('name', 'Child campaign 1');
        grandchildCampaign2.put('reason', 'The campaign is newest');
        grandchildCampaign2.put('status', 'Published');
        grandchildCampaign2.put('goalAmount', '452');
        grandchildCampaign2.put('parentGoalId', parentGoalId);
        grandchildCampaign2.put('goalId', grandchildGoalId2);
        grandchildCampaign2.put('deleted', true);
        
        Campaign parentCampaign = [SELECT Id, fr_ID__c FROM Campaign WHERE fr_ID__c = :parentGoalId];
        List<Campaign> childCampaigns = [SELECT Id, fr_ID__c, Name, ParentId FROM Campaign WHERE parentId = :parentCampaign.Id];
        System.assertEquals(childCampaigns.size(), 2, 'Number of children is incorrect');

        Test.startTest();
        new frCampaign(grandchildCampaign2);
        Test.stopTest();

        childCampaigns = [SELECT Id, fr_ID__c, Name, ParentId FROM Campaign WHERE parentId = :parentCampaign.Id];
        System.assertEquals(childCampaigns.size(), 1, 'Number of children is incorrect');
    }
    
    static testMethod void testUpdateCampaign() {
        createCampaigns();
        
        String updatedName = 'Grandchild Campaign';
        String updatedReason = 'The campaign is bold';
        Decimal updatedGoal = 899;

        Map<String, Object> grandchildCampaign2 = new Map<String, Object>();
        grandchildCampaign2.put('name', updatedName);
        grandchildCampaign2.put('reason', updatedReason);
        grandchildCampaign2.put('status', 'Published');
        grandchildCampaign2.put('goalAmount', updatedGoal);
        grandchildCampaign2.put('parentGoalId', parentGoalId);
        grandchildCampaign2.put('goalId', grandchildGoalId2);
        grandchildCampaign2.put('deleted', false);

        Test.startTest();
        new frCampaign(grandchildCampaign2);
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
        Map<String, Object> request = new Map<String, Object>();
        request.put('name', campaignName);
        request.put('reason', 'The campaign is new');
        request.put('status', 'Published');
        request.put('goalAmount', '238329.12');
        request.put('parentGoalId', null);
        request.put('supporterId', fundraiser.fr_Id__c);
        request.put('goalId', goalId);
        request.put('deleted', false);

        Test.startTest();
        Integer startingErrors = [SELECT COUNT() FROM Error__c];
        new frCampaign(request);
        
        //the same request twice shouldn't duplicate campaign members
        new frCampaign(request);
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
        Map<String, Object> topLevelCampaign = new Map<String, Object>();
        topLevelCampaign.put('name', 'Top level Campaign');
        topLevelCampaign.put('reason', 'The campaign is old');
        topLevelCampaign.put('status', 'Published');
        topLevelCampaign.put('goalAmount', '238329.12');
        topLevelCampaign.put('parentGoalId', null);
        topLevelCampaign.put('goalId', topLevelGoalId);
        topLevelCampaign.put('deleted', false);
        
        Map<String, Object> childCampaign = new Map<String, Object>();
        childCampaign.put('name', 'Second Level Campaign');
        childCampaign.put('reason', 'The campaign is new');
        childCampaign.put('status', 'Published');
        childCampaign.put('goalAmount', '1200');
        childCampaign.put('parentGoalId', topLevelGoalId);
        childCampaign.put('goalId', parentGoalId);
        childCampaign.put('deleted', false);
        
        Map<String, Object> grandchildCampaign1 = new Map<String, Object>();
        grandchildCampaign1.put('name', 'Child campaign 1');
        grandchildCampaign1.put('reason', 'The campaign is newer');
        grandchildCampaign1.put('status', 'Published');
        grandchildCampaign1.put('goalAmount', '232');
        grandchildCampaign1.put('parentGoalId', parentGoalId);
        grandchildCampaign1.put('goalId', grandchildGoalId1);
        grandchildCampaign1.put('deleted', false);
        
        Map<String, Object> grandchildCampaign2 = new Map<String, Object>();
        grandchildCampaign2.put('name', 'Child campaign 1');
        grandchildCampaign2.put('reason', 'The campaign is newest');
        grandchildCampaign2.put('status', 'Published');
        grandchildCampaign2.put('goalAmount', '452');
        grandchildCampaign2.put('parentGoalId', parentGoalId);
        grandchildCampaign2.put('goalId', grandchildGoalId2);
        grandchildCampaign2.put('deleted', false);
        
        new frCampaign(topLevelCampaign);
        new frCampaign(childCampaign);
        new frCampaign(grandchildCampaign1);
        new frCampaign(grandchildCampaign2);
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
}