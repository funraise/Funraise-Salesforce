/*
*
*  Copyright (c) 2019, Funraise Inc
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
public class frDonationTest {

    //
    // syncEntity_newDonor
    //
    static testMethod void syncEntity_newDonor() {
        if (frUtil.hasNPCobjects()) {
            return; // skip in NPC org
        }
        createMapping('name', 'Name');
        createMapping('name', 'Description');
        createMapping('amount', 'amount');
        createMapping('donation_cretime', 'CloseDate');

        insert new frMapping__c(Name = 'Test String', Is_Constant__c = true, Constant_Value__c = 'Closed Won',
                                sf_Name__c = 'StageName', Type__c = frDonation.TYPE);
        insert new frMapping__c(Name = 'Test Percent', Is_Constant__c = true, Constant_Value__c = '95',
                                sf_Name__c = 'Probability', Type__c = frDonation.TYPE);
        insert new frMapping__c(Name = 'Test Double', Is_Constant__c = true, Constant_Value__c = '1.5',
                                sf_Name__c = 'totalopportunityquantity', Type__c = frDonation.TYPE);

        frTestUtil.createTestPost(getTestRequest());
        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();

        String oppFrId = String.valueOf(getTestRequest().get('id'));
        Opportunity newOpportunity = [
            SELECT Id, fr_ID__c, StageName, Name, Description, Probability, TotalOpportunityQuantity
            FROM Opportunity
            WHERE fr_Id__c = :oppFrId
        ];
        System.assertEquals('Closed Won', newOpportunity.StageName, 'The constant mapping for StageName was not used');
        System.assertEquals(95, newOpportunity.Probability, 'The constant mapping for Probability was not used');
        System.assertEquals(1.5, newOpportunity.TotalOpportunityQuantity, 'The constant mapping for Total Opportunity Quantity was not used');

        String expectedNameAndDesc = String.valueOf(getTestRequest().get('name'));
        System.assertEquals(expectedNameAndDesc, newOpportunity.Name, 'The mapping for name should have been applied');
        System.assertEquals(expectedNameAndDesc, newOpportunity.Description, 'The mapping for desc should have been applied');
    }

    static testMethod void syncEntity_newDonor_NPC() {
        if (!frUtil.hasNPCobjects()) {
            return; // skip in non-NPC org
        }
        createMapping('name', 'Name');
        createMapping('name', 'Description');
        createMapping('amount', 'OriginalAmount');
        insert new frMapping__c(Name = 'Test String', Is_Constant__c = true, Constant_Value__c = 'Closed Won',
                                sf_Name__c = 'StageName', Type__c = frDonation.TYPE);
        insert new frMapping__c(Name = 'Test Percent', Is_Constant__c = true, Constant_Value__c = '95',
                                sf_Name__c = 'Probability', Type__c = frDonation.TYPE);
        insert new frMapping__c(Name = 'Test Double', Is_Constant__c = true, Constant_Value__c = '1.5',
                                sf_Name__c = 'totalopportunityquantity', Type__c = frDonation.TYPE);
        insert frSetupController.getGiftTransactionDefaults();

        frTestUtil.createTestPost(getTestRequest());
        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();

        String oppFrId = String.valueOf(getTestRequest().get('id'));
        List<SObject> gt = Database.query(
            'SELECT Id, Name, Description '+ //, StageName__c, Probability__c, TotalOpportunityQuantity__c ' +
            'FROM GiftTransaction ' +
            'WHERE fr_ID__c = :oppFrId'
        );
        //System.assertEquals('Closed Won', (String)gt[0].get('StageName__c'));
        //System.assertEquals(95, (Decimal)gt[0].get('Probability__c'));
        //System.assertEquals(1.5, (Decimal)gt[0].get('TotalOpportunityQuantity__c'));

        String expectedNameAndDesc = String.valueOf(getTestRequest().get('name'));
        System.assertEquals(expectedNameAndDesc, (String)gt[0].get('Name'));
        System.assertEquals(expectedNameAndDesc, (String)gt[0].get('Description'));
    }

    //
    // syncEntity_existingDonor
    //
    static testMethod void syncEntity_existingDonor() {
        if (frUtil.hasNPCobjects()) {
            return;
        }
        Contact testContact = frDonorTest.getTestContact();
        createMapping('name', 'Name');
        createMapping('donation_cretime', 'CloseDate');

        frTestUtil.createTestPost(getTestRequest());

        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();

        frTestUtil.assertNoErrors();
        String oppFrId = String.valueOf(getTestRequest().get('id'));
        Opportunity newOpportunity = [
            SELECT fr_Donor__c
            FROM Opportunity
            WHERE fr_Id__c = :oppFrId
        ];
        System.assertEquals(testContact.Id, newOpportunity.fr_Donor__c,
                            'The funraise sf donor id was not populated to the opportunity\'s contact lookup field');
    }

    static testMethod void syncEntity_existingDonor_NPC() {
        if (!frUtil.hasNPCobjects()) {
            return;
        }
        Contact testContact = frDonorTest.getTestContact();
        Account testAccount = frDonorTest.getTestAccount(true);
        insert frSetupController.getGiftTransactionDefaults();
        createMapping('name', 'Name');

        Map<String, Object> request = getTestRequest();
        request.put('donorId', '856');
        frTestUtil.createTestPost(request);

        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();

        String oppFrId = String.valueOf(getTestRequest().get('id'));
        frTestUtil.assertNoErrors();
        List<SObject> gt = Database.query(
            'SELECT Id, Name, DonorId FROM GiftTransaction WHERE fr_ID__c = :oppFrId'
        );
        System.assertEquals(testAccount.Id, gt[0].get('DonorId'));
    }

    //
    // syncEntity_CampaignDonation
    //
    static testMethod void syncEntity_CampaignDonation() {
        if (frUtil.hasNPCobjects()) {
            return;
        }
        createMapping('name', 'Name');
        createMapping('donation_cretime', 'CloseDate');
        Contact testContact = frDonorTest.getTestContact();

        Campaign testCampaign = new Campaign(fr_ID__c = '10', Name = 'Test Campaign',
                                             ExpectedRevenue = 123, Description = 'Test', Status = 'Published');
        insert testCampaign;

        Map<String, Object> request = getTestRequest();
        request.put('campaignGoalId', 10);
        request.put('campaignMappingDisabled', false);

        frTestUtil.createTestPost(request);
        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();

        frTestUtil.assertNoErrors();
        String oppFrId = String.valueOf(getTestRequest().get('id'));
        Opportunity newOpportunity = [
            SELECT fr_ID__c, fr_Donor__c, CampaignId
            FROM Opportunity
            WHERE fr_Id__c = :oppFrId
        ];
        System.assertEquals(testContact.Id, newOpportunity.fr_Donor__c,
                            'The funraise sf donor id was not populated to the opportunity\'s contact lookup field');
        System.assertEquals(testCampaign.Id, newOpportunity.CampaignId,
                            'The campaign Id was not added to the donation');
    }

    static testMethod void syncEntity_CampaignDonation_NPC() {
        if (!frUtil.hasNPCobjects()) {
            return;
        }
        createMapping('name', 'Name');
        insert frSetupController.getGiftTransactionDefaults();
        Contact testContact = frDonorTest.getTestContact();
        Account testAccount = frDonorTest.getTestAccount(true);
        Campaign testCampaign = new Campaign(fr_ID__c = '10', Name = 'Test Campaign',
                                             ExpectedRevenue = 123, Description = 'Test', Status = 'Published');
        insert testCampaign;

        Map<String,Object> req = getTestRequest();
        req.put('donorId', '856');
        req.put('campaignGoalId', 10);
        req.put('campaignMappingDisabled', false);
        frTestUtil.createTestPost(req);

        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();

        String oppFrId = String.valueOf(req.get('id'));
        frTestUtil.assertNoErrors();
        List<SObject> gt = Database.query(
            'SELECT Id, Name, DonorId, CampaignId FROM GiftTransaction WHERE fr_ID__c = :oppFrId'
        );
        System.assertEquals(testAccount.Id, gt[0].get('DonorId'));
        System.assertEquals(testCampaign.Id, gt[0].get('CampaignId'));
    }

    //
    // syncEntity_donationStatusDefaulting
    //
    static testMethod void syncEntity_donationStatusDefaulting() {
        if (frUtil.hasNPCobjects()) {
            return;
        }
        Contact testContact = frDonorTest.getTestContact();

        Campaign testCampaign = new Campaign(fr_ID__c = '10', Name = 'Test Campaign', 
                                             ExpectedRevenue = 123, Description = 'Test', Status = 'Published');
        insert testCampaign;

        createMapping('name', 'Name');
        createMapping('donation_cretime', 'CloseDate');

        Map<String, Object> request = getTestRequest();
        request.put('status', 'Refunded');
        frTestUtil.createTestPost(request);

        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();

        frTestUtil.assertNoErrors();
        String oppFrId = String.valueOf(getTestRequest().get('id'));
        Opportunity newOpportunity = [SELECT Id, StageName, fr_ID__c, fr_Donor__c FROM Opportunity WHERE fr_Id__c = :oppFrId];
        System.assertEquals('Closed Lost', newOpportunity.StageName, 'A status of refunded should have resulted in a Closed Lost stage');
    }

    //
    // syncEntity_newOpportunityRoleMappings
    //
    static testMethod void syncEntity_newOpportunityRoleMappings() {
        if (frUtil.hasNPCobjects()) {
            return;
        }
        createMapping('name', 'Name');
        createMapping('donation_cretime', 'CloseDate');

        Contact donor = frDonorTest.getTestContact(false);
        donor.fr_Id__c = '1';
        donor.Email = 'donor@example.com';
        Contact fundraiser = frDonorTest.getTestContact(false);
        fundraiser.fr_Id__c = '2';
        fundraiser.Email = 'fundraiser@example.com';
        Contact teamCaptain = frDonorTest.getTestContact(false);
        teamCaptain.fr_Id__c = '3';
        teamCaptain.Email = 'teamCaptain@example.com';
        insert new List<Contact>{donor, fundraiser, teamCaptain};

        Map<String, Object> request = getTestRequest();
        request.put('opportunityContactMappingDisabled', 'false');
        request.put('donorId', donor.fr_Id__c);
        request.put('fundraiserId', fundraiser.fr_ID__c);
        request.put('teamCaptainId', teamCaptain.fr_ID__c);

        frTestUtil.createTestPost(request);
        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();

        frTestUtil.assertNoErrors();

        String oppFrId = String.valueOf(getTestRequest().get('id'));
        Opportunity newOpportunity = [SELECT Id, fr_ID__c, fr_Donor__c, (SELECT Id, ContactId, Role FROM OpportunityContactRoles) FROM Opportunity WHERE fr_Id__c = :oppFrId];
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

    static testMethod void syncEntity_newOpportunityRoleMappings_NPC() {
        if (!frUtil.hasNPCobjects()) {
            return;
        }
        insert frSetupController.getGiftTransactionDefaults();
        // Original code had no else logic for the NPC scenario (it was blank).
        // If you want to test a similar scenario in NPC, add it here.
    }

    //
    // syncEntity_newOpportunityRoleMappings_missingContacts
    //
    static testMethod void syncEntity_newOpportunityRoleMappings_missingContacts() {
        if (frUtil.hasNPCobjects()) {
            return;
        }
        createMapping('name', 'Name');
        createMapping('donation_cretime', 'CloseDate');

        Contact donor = frDonorTest.getTestContact(false);
        donor.fr_Id__c = '1';
        donor.Email = 'donor@example.com';
        Contact fundraiser = frDonorTest.getTestContact(false);
        fundraiser.fr_Id__c = '2';
        fundraiser.Email = 'fundraiser@example.com';
        Contact teamCaptain = frDonorTest.getTestContact(false);
        teamCaptain.fr_Id__c = '3';
        teamCaptain.Email = 'teamCaptain@example.com';
        insert new List<Contact>{donor, fundraiser, teamCaptain};

        Map<String, Object> request = getTestRequest();
        request.put('opportunityContactMappingDisabled', 'false');
        request.put('donorId', donor.fr_Id__c);
        request.put('fundraiserId', fundraiser.fr_ID__c+'1');
        request.put('teamCaptainId', teamCaptain.fr_ID__c+'1');

        frTestUtil.createTestPost(request);
        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();

        String oppFrId = String.valueOf(getTestRequest().get('id'));
        Opportunity newOpportunity = [SELECT Id, fr_ID__c, fr_Donor__c, (SELECT Id, ContactId, Role FROM OpportunityContactRoles) FROM Opportunity WHERE fr_Id__c = :oppFrId];
        List<OpportunityContactRole> roles = newOpportunity.OpportunityContactRoles;
        System.assertEquals(1, roles.size(), 'Since the request had ids that did not exist in SF, no roles should have been created except for the donor');
        System.assertEquals(2, [SELECT COUNT() FROM Error__c], 'There should be 3 error logs for missing supporters that prevented opp roles from being created');
    }

    static testMethod void syncEntity_newOpportunityRoleMappings_missingContacts_NPC() {
        if (!frUtil.hasNPCobjects()) {
            return;
        }
        // Original code had no else logic for NPC. 
        // If needed, you can replicate the scenario in NPC or skip.
    }

    //
    // syncEntity_LinkToSubscription
    //
    static testMethod void syncEntity_LinkToSubscription() {
        if (frUtil.hasNPCobjects()) {
            return;
        }
        createMapping('name', 'Name');
        createMapping('donation_cretime', 'CloseDate');

        Contact testSupporter = frDonorTest.getTestContact();

        Subscription__c subscription = new Subscription__c(Name = 'Test Sub', fr_ID__c = '1234', Supporter__c = testSupporter.Id);
        insert subscription;

        Map<String, Object> request = getTestRequest();
        request.put('subscriptionId', subscription.fr_ID__c);

        frTestUtil.createTestPost(request);
        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();

        frTestUtil.assertNoErrors();

        String oppFrId = String.valueOf(getTestRequest().get('id'));
        Opportunity newOpportunity = [SELECT Id, fr_ID__c, Subscription__c FROM Opportunity WHERE fr_Id__c = :oppFrId];
        System.assertEquals(subscription.Id, newOpportunity.Subscription__c, 'The new donation should be pointing at the subscription corresponding to the id provided in the request');
    }

    static testMethod void syncEntity_LinkToSubscription_NPC() {
        if (!frUtil.hasNPCobjects()) {
            return;
        }
        insert frSetupController.getGiftTransactionDefaults();
        createMapping('name', 'Name');
        createMapping('amount', 'OriginalAmount');
        createMapping('donation_cretime', 'TransactionDueDate');

        insert new frMapping__c(Type__c = 'Gift Transaction', Name = 'donation_cretime',
                                fr_Name__c = 'donation_cretime', sf_Name__c = 'CheckDate');

        Contact testSupporter = frDonorTest.getTestContact();
        Account testAccount = frDonortest.getTestAccount(true);

        Subscription__c subscription = new Subscription__c(Name = 'Test Sub', fr_ID__c = '1234', Supporter__c = testSupporter.Id);
        insert subscription;

        SObject matchingNPCrecord = Schema.getGlobalDescribe().get('giftcommitment').newSObject();
        matchingNPCrecord.put('fr_ID__c', '1234');
        matchingNPCrecord.put('Name', 'Test Sub');
        matchingNPCrecord.put('DonorId', testAccount.Id);
        insert matchingNPCrecord;

        Map<String, Object> request = getTestRequest();
        request.put('subscriptionId', subscription.fr_ID__c);
        request.put('APEX_TESTS', 'true');
        request.put('opportunityContactMappingDisabled', 'false');
        request.put('donorId', '856');

        frTestUtil.createTestPost(request);
        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();

        String oppFrId = String.valueOf(request.get('id'));
        frTestUtil.assertNoErrors();
        List<SObject> gt = Database.query('SELECT Id, Name, DonorId, GiftCommitmentId FROM GiftTransaction WHERE fr_ID__c = :oppFrId');
        List<SObject> gc = Database.query('SELECT Id FROM GiftCommitment WHERE fr_ID__c = \'1234\'');
        System.assertEquals(gc[0].Id, gt[0].get('GiftCommitmentId'));
    }

    //
    // syncEntity_LinkToPledge
    //
    static testMethod void syncEntity_LinkToPledge() {
        if (frUtil.hasNPCobjects()) {
            return;
        }
        createMapping('name', 'Name');
        createMapping('donation_cretime', 'CloseDate');

        Contact testSupporter = frDonorTest.getTestContact();

        Pledge__c pledge = getTestPledge(testSupporter);
        insert pledge;

        frTestUtil.createTestPost(getTestRequest());
        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();

        frTestUtil.assertNoErrors();
        String oppFrId = String.valueOf(getTestRequest().get('id'));
        Opportunity newOpportunity = [SELECT Id, fr_ID__c, Funraise_Pledge__c FROM Opportunity WHERE fr_Id__c = :oppFrId];
        System.assertEquals(pledge.Id, newOpportunity.Funraise_Pledge__c, 'The new donation should be pointing at the pledge that the supporter had active');
    }

    static testMethod void syncEntity_LinkToPledge_NPC() {
        if (!frUtil.hasNPCobjects()) {
            return;
        }
        createMapping('name', 'Name');
        insert frSetupController.getGiftTransactionDefaults();
        insert new frMapping__c(Type__c = 'Gift Transaction', Name = 'donation_cretime',
                                fr_Name__c = 'donation_cretime', sf_Name__c = 'CheckDate');

        Contact testSupporter = frDonorTest.getTestContact();
        Account testAccount = frDonortest.getTestAccount(true);

        Pledge__c pledge = getTestPledgeAcc(testAccount);
        insert pledge;

        Map<String, Object> request = getTestRequest();
        request.put('donorId', '856');
        request.put('pledge', true);
        frTestUtil.createTestPost(request);

        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();

        List<SObject> gt = Database.query('SELECT Id, OriginalAmount, fr_ID__c, Funraise_GT_Pledge__c FROM GiftTransaction');
        System.assertNotEquals(null, gt[0].get('Funraise_GT_Pledge__c'));
    }

    //
    // syncEntity_PledgeCreatesPledge
    //
    static testMethod void syncEntity_PledgeCreatesPledge() {
        if (frUtil.hasNPCobjects()) {
            return;
        }
        createMapping('name', 'Name');
        createMapping('amount', 'amount');
        createMapping('donation_cretime', 'CloseDate');

        Contact testSupporter = frDonorTest.getTestContact();

        Map<String, Object> request = getTestRequest();
        request.put('pledge', true);

        frTestUtil.createTestPost(request);
        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();

        frTestUtil.assertNoErrors();
        String oppFrId = String.valueOf(getTestRequest().get('id'));
        Opportunity opp = [SELECT Id, Amount, fr_ID__c, Funraise_Pledge__c FROM Opportunity WHERE fr_Id__c = :oppFrId];
        System.assertNotEquals(null, opp.Funraise_Pledge__c, 'The new donation should have created a new pledge');
        Pledge__c pledge = [SELECT Pledge_Donation_uq__c , Pledge_Donation__c, Pledge_Amount__c, Received_Amount__c from Pledge__c
                            WHERE Id = :opp.Funraise_Pledge__c];
        System.assertEquals(pledge.Pledge_Donation_uq__c, opp.Id, 'The one-time pledge should have a reference to the one-time donation that created it');
        System.assertEquals(pledge.Pledge_Donation__c, opp.Id, 'The one-time pledge should have a reference to the one-time donation that created it');
        System.assertEquals(pledge.Pledge_Amount__c, opp.Amount, 'The pledged amount should be the same as the opportunity amount');
        System.assertEquals(pledge.Received_Amount__c, opp.Amount, 'The receive amount should be the same as the opportunity amount since the opp is Closed Won');
    }

    static testMethod void syncEntity_PledgeCreatesPledge_NPC() {
        if (!frUtil.hasNPCobjects()) {
            return;
        }
        Account testAccount = frDonortest.getTestAccount(true);
        
        createMapping('name', 'Name');
        createMapping('amount', 'OriginalAmount');
        insert frSetupController.getGiftTransactionDefaults();
        insert new frMapping__c(Type__c = 'Gift Transaction', Name = 'donation_cretime',
                                fr_Name__c = 'donation_cretime', sf_Name__c = 'CheckDate');

        Map<String, Object> request = getTestRequest();
        request.put('pledge', true);
        request.put('donorId', '856');

        frTestUtil.createTestPost(request);
        
        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();

        frTestUtil.assertNoErrors();
        List<SObject> gt = Database.query('SELECT Id, OriginalAmount, fr_ID__c, Funraise_GT_Pledge__c FROM GiftTransaction');
        System.assertNotEquals(null, gt[0].get('Funraise_GT_Pledge__c'));
        Pledge__c pledge = [
            SELECT Pledge_Donation_uq__c, Pledge_Donation__c, Pledge_Amount__c, Received_Amount__c
            FROM Pledge__c
            WHERE Id = :(Id) gt[0].get('Funraise_GT_Pledge__c')
        ];
        System.assertEquals(gt[0].get('OriginalAmount'), pledge.Pledge_Amount__c);
    }

    //
    // syncEntity_PledgeUpdatesPledge
    //
    static testMethod void syncEntity_PledgeUpdatesPledge() {
        if (frUtil.hasNPCobjects()) {
            return;
        }
        createMapping('name', 'Name');
        createMapping('amount', 'amount');
        createMapping('donation_cretime', 'CloseDate');
        Contact testSupporter = frDonorTest.getTestContact();

        Opportunity existingOpp = getTestOpp();
        existingOpp.fr_Id__c = '2048';
        insert existingOpp;

        Pledge__c pledge = getTestPledge(testSupporter);
        pledge.Pledge_Donation__c = existingOpp.Id;
        insert pledge;

        existingOpp.Funraise_Pledge__c = pledge.Id;
        update existingOpp;

        //requery to get the workflow rule update on pledge_donation_uq__c
        pledge = [SELECT Id, Pledge_Donation__c, Pledge_Donation_uq__c FROM Pledge__c WHERE Id = :pledge.Id];
        System.assertEquals(pledge.Pledge_Donation__c +'', pledge.Pledge_Donation_uq__c+'',
                            'The external id unique field should have been updated with the value from the lookup field');


        Map<String, Object> request = getTestRequest();
        request.put('pledge', true);

        frTestUtil.createTestPost(request);
        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();

        frTestUtil.assertNoErrors();

        String oppFrId = String.valueOf(getTestRequest().get('id'));
        Opportunity opp = [SELECT Id, Amount, fr_ID__c, Funraise_Pledge__c FROM Opportunity WHERE fr_Id__c = :oppFrId];
        System.assertNotEquals(null, opp.Funraise_Pledge__c, 'The new donation should have created a new pledge');
        pledge = [SELECT Pledge_Donation_uq__c , Pledge_Donation__c, Pledge_Amount__c, Received_Amount__c from Pledge__c
                  WHERE Id = :opp.Funraise_Pledge__c];
        System.assertEquals(pledge.Pledge_Donation_uq__c, opp.Id, 'The one-time pledge should have a reference to the one-time donation that created it');
        System.assertEquals(pledge.Pledge_Donation__c, opp.Id, 'The one-time pledge should have a reference to the one-time donation that created it');
        System.assertEquals(pledge.Pledge_Amount__c, opp.Amount, 'The pledged amount should be the same as the opportunity amount');
        System.assertEquals(pledge.Received_Amount__c, opp.Amount, 'The receive amount should be the same as the opportunity amount since the opp is Closed Won');
    }

    static testMethod void syncEntity_PledgeUpdatesPledge_NPC() {
        if (!frUtil.hasNPCobjects()) {
            return;
        }
        Account testAccount = frDonorTest.getTestAccount(true);

        createMapping('name', 'Name');
        createMapping('amount', 'OriginalAmount');
        insert frSetupController.getGiftTransactionDefaults();
        insert new frMapping__c(Type__c = 'Gift Transaction', Name = 'donation_cretime',
                                fr_Name__c = 'donation_cretime', sf_Name__c = 'CheckDate');

        Opportunity existingOpp = getTestOpp();
        existingOpp.fr_Id__c = '2048';
        insert existingOpp;

        Contact testSupporter = frDonorTest.getTestContact();
        Pledge__c pledge = getTestPledge(testSupporter);
        pledge.Pledge_Donation__c = existingOpp.Id;
        insert pledge;

        SObject existingGT = getTestGT();
        existingGT.put('fr_Id__c', '2048');
        existingGT.put('Funraise_GT_Pledge__c', pledge.Id);
        insert existingGT;

        existingOpp.Funraise_Pledge__c = pledge.Id;
        update existingOpp;
        existingGT.put('Funraise_GT_Pledge__c', pledge.Id);
        update existingGT;

        Map<String, Object> request = getTestRequest();
        request.put('pledge', true);
        request.put('donorId', '856');
        frTestUtil.createTestPost(request);

        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();
        frTestUtil.assertNoErrors();

        List<SObject> gt = Database.query(
            'SELECT Id, OriginalAmount, fr_ID__c, Funraise_GT_Pledge__c FROM GiftTransaction'
        );
        System.assertNotEquals(null, gt[0].get('Funraise_GT_Pledge__c'));
        pledge = [
            SELECT Pledge_Donation_uq__c, Pledge_Donation__c, Pledge_Amount__c, Received_Amount__c
            FROM Pledge__c
            WHERE Id = :(Id) gt[0].get('Funraise_GT_Pledge__c')
        ];
        System.assertEquals(gt[0].get('OriginalAmount'), pledge.Pledge_Amount__c);
    }

    //
    // syncEntity_existing_alreadyLinkedToPledge
    //
    static testMethod void syncEntity_existing_alreadyLinkedToPledge() {
        if (frUtil.hasNPCobjects()) {
            return;
        }
        createMapping('name', 'Name');
        createMapping('amount', 'amount');
        createMapping('donation_cretime', 'CloseDate');

        Contact testSupporter = frDonorTest.getTestContact();
        Pledge__c pledge = getTestPledge(testSupporter);
        pledge.End_Date__c = Date.today().addDays(-1); //so it's no longer active
        insert pledge;
        Opportunity existingOpp = getTestOpp();
        existingOpp.fr_Id__c = '2048';
        existingOpp.Funraise_Pledge__c = pledge.Id;
        insert existingOpp;

        Map<String, Object> request = getTestRequest();
        request.put('id', existingOpp.fr_Id__c);

        frTestUtil.createTestPost(request);
        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();

        frTestUtil.assertNoErrors();

        String oppFrId = String.valueOf(getTestRequest().get('id'));
        Opportunity opp = [SELECT Id, Funraise_Pledge__c FROM Opportunity WHERE fr_Id__c = :oppFrId];
        System.assertEquals(pledge.Id, opp.Funraise_Pledge__c, 'The pledge value should remain unchanged');
    }

    static testMethod void syncEntity_existing_alreadyLinkedToPledge_NPC() {
        if (!frUtil.hasNPCobjects()) {
            return;
        }
        createMapping('name', 'Name');
        createMapping('amount', 'OriginalAmount');
        createMapping('donation_cretime', 'CheckDate');
        insert frSetupController.getGiftTransactionDefaults();

        Contact testSupporter = frDonorTest.getTestContact();
        Account testAccount = frDonortest.getTestAccount(true);
        Pledge__c pledge = getTestPledgeAcc(testAccount);
        pledge.End_Date__c = Date.today().addDays(-1);
        insert pledge;

        SObject existingGT = getTestGT();
        existingGT.put('fr_Id__c', '2048');
        existingGT.put('Funraise_GT_Pledge__c', pledge.Id);
        insert existingGT;

        Map<String, Object> request = getTestRequest();
        request.put('id', existingGT.get('fr_Id__c'));
        request.put('donorId', '856');
        frTestUtil.createTestPost(request);

        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();

        String requestId = (String) request.get('id');
        List<SObject> gc = Database.query(
            'SELECT Id, Funraise_GT_Pledge__c FROM GiftTransaction WHERE fr_ID__c = :requestId'
        );
        System.assertEquals(pledge.Id, gc[0].get('Funraise_GT_Pledge__c'), 'The pledge value should remain unchanged');
    }

    //
    // syncEntity_oldDonation_matchesInactivePledge
    //
    static testMethod void syncEntity_oldDonation_matchesInactivePledge() {
        if (frUtil.hasNPCobjects()) {
            return;
        }
        createMapping('name', 'Name');
        createMapping('amount', 'amount');
        createMapping('donation_cretime', 'CloseDate');

        Contact testSupporter = frDonorTest.getTestContact();
        //get a pledge that is inactive according to dates
        //but is unfulfilled in amount
        Pledge__c pledge = getTestPledge(testSupporter);
        pledge.Start_Date__c = Date.today().addDays(-5);
        pledge.End_Date__c = Date.today().addDays(-1);
        insert pledge;

        Map<String, Object> request = getTestRequest();
        request.put('donation_cretime', DateTime.now().addDays(-3).getTime());

        frTestUtil.createTestPost(request);
        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();

        frTestUtil.assertNoErrors();

        String oppFrId = String.valueOf(getTestRequest().get('id'));
        Opportunity opp = [SELECT Id, Funraise_Pledge__c FROM Opportunity WHERE fr_Id__c = :oppFrId];
        System.assertEquals(pledge.Id, opp.Funraise_Pledge__c, 'The donation should have matched to a previously active unfulfilled pledge');
    }

    static testMethod void syncEntity_oldDonation_matchesInactivePledge_NPC() {
        if (!frUtil.hasNPCobjects()) {
            return;
        }
        createMapping('name', 'Name');
        createMapping('amount', 'OriginalAmount');
        //createMapping('donation_cretime', 'TransactionDueDate');
        createMapping('donation_cretime', 'CheckDate');
        insert frSetupController.getGiftTransactionDefaults();

        Contact testSupporter = frDonorTest.getTestContact();
        Account testAccount = frDonortest.getTestAccount(true);
        Pledge__c pledge = getTestPledgeAcc(testAccount);
        pledge.Start_Date__c = Date.today().addDays(-5);
        pledge.End_Date__c = Date.today().addDays(-1);
        insert pledge;

        Map<String, Object> req = getTestRequest();
        req.put('donation_cretime', DateTime.now().addDays(-3).getTime());
        req.put('donorId', testAccount.get('fr_Id__c'));
        frTestUtil.createTestPost(req);

        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();
        frTestUtil.assertNoErrors();

        String oppFrId = String.valueOf(req.get('id'));
        List<SObject> gc = Database.query(
            'SELECT Funraise_GT_Pledge__c ' +
            'FROM GiftTransaction ' +
            'WHERE fr_ID__c = :oppFrId'
        );
        System.assertEquals(pledge.Id, gc[0].get('Funraise_GT_Pledge__c'), 'The donation should have matched to a previously active unfulfilled pledge');
    }

    //
    // syncEntity_oldDonation_doesNotMatchInactivePledge
    //
    static testMethod void syncEntity_oldDonation_doesNotMatchInactivePledge() {
        if (frUtil.hasNPCobjects()) {
            return;
        }
        createMapping('name', 'Name');
        createMapping('amount', 'amount');
        createMapping('donation_cretime', 'CloseDate');

        Contact testSupporter = frDonorTest.getTestContact();
        //get a pledge that is inactive according to dates
        //but is unfulfilled in amount
        Pledge__c pledge = getTestPledge(testSupporter);
        pledge.Start_Date__c = Date.today().addDays(-5);
        pledge.End_Date__c = Date.today().addDays(-1); 
        insert pledge;

        Map<String, Object> request = getTestRequest();
        request.put('donation_cretime', DateTime.now().getTime());

        frTestUtil.createTestPost(request);
        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();

        frTestUtil.assertNoErrors();

        String oppFrId = String.valueOf(getTestRequest().get('id'));
        Opportunity opp = [SELECT Id, Funraise_Pledge__c FROM Opportunity WHERE fr_Id__c = :oppFrId];
        System.assertEquals(null, opp.Funraise_Pledge__c, 'The donation should not have matched to a previously active unfulfilled pledge');
    }

    static testMethod void syncEntity_oldDonation_doesNotMatchInactivePledge_NPC() {
        if (!frUtil.hasNPCobjects()) {
            return;
        }
        createMapping('name', 'Name');
        createMapping('amount', 'OriginalAmount');
        insert frSetupController.getGiftTransactionDefaults();

        Contact testSupporter = frDonorTest.getTestContact();
        Account testAccount = frDonortest.getTestAccount(true);
        Pledge__c pledge = getTestPledgeAcc(testAccount);
        pledge.Start_Date__c = Date.today().addDays(-5);
        pledge.End_Date__c = Date.today().addDays(-1);
        insert pledge;

        Map<String, Object> req = getTestRequest();
        req.put('donation_cretime', DateTime.now().getTime());
        req.put('donorId', '856');
        frTestUtil.createTestPost(req);

        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();

        // The original code didn't do an assertion for the else block
        // If you'd like to assert it's null, you can do so
    }

    //
    // syncEntity_oppContactRoles_sameSupporter
    //
    static testMethod void syncEntity_oppContactRoles_sameSupporter() {
        if (frUtil.hasNPCobjects()) {
            return;
        }
        createMapping('name', 'Name');
        createMapping('amount', 'amount');
        createMapping('donation_cretime', 'CloseDate');
        Contact testSupporter = frDonorTest.getTestContact();

        Map<String, Object> request = getTestRequest();
        request.put('opportunityContactMappingDisabled', false);
        request.put('donorId', testSupporter.fr_Id__c);
        request.put('fundraiserId', testSupporter.fr_Id__c);
        request.put('teamCaptainId', testSupporter.fr_Id__c);
        request.put('softCreditSupporterId', testSupporter.fr_Id__c);

        frTestUtil.createTestPost(request);
        Test.startTest();
        frWSDonationController.syncEntity();
        Test.stopTest();

        frTestUtil.assertNoErrors();

        String oppFrId = String.valueOf(getTestRequest().get('id'));
        Set<String> funraiseRoles = new Set<String>{
            frDonation.OPP_ROLE_DONOR,
            frDonation.OPP_ROLE_FUNDRAISER,
            frDonation.OPP_ROLE_SOFT_CREDIT,
            frDonation.OPP_ROLE_TEAM_CAPTAIN
        };
        Opportunity opp = [SELECT Id, Funraise_Pledge__c,
                           (SELECT Id, Role FROM OpportunityContactRoles WHERE ContactId = :testSupporter.Id AND role IN :funraiseRoles)
                           FROM Opportunity WHERE fr_Id__c = :oppFrId];
        System.assertEquals(1, opp.OpportunityContactRoles.size(),
                            'There should be a single opp contact role for the supporter');
        System.assertEquals(frDonation.OPP_ROLE_DONOR, opp.OpportunityContactRoles.get(0).role,
                           'The single opp contact role should be the donor role');
    }

    static testMethod void syncEntity_oppContactRoles_sameSupporter_NPC() {
        if (!frUtil.hasNPCobjects()) {
            return;
        }
        insert frSetupController.getGiftTransactionDefaults();
        createMapping('name', 'Name');
        createMapping('amount', 'OriginalAmount');
        // Original code had no else logic for NPC scenario
        // If needed, replicate a GiftTransaction approach here
    }

    static testMethod void syncEntity_setOpportunityStage_NPC() {
        if (!frUtil.hasNPCobjects()) {
            return;
        }

        createMapping('name', 'Name');
        insert frSetupController.getGiftTransactionDefaults();
        Contact testContact = frDonorTest.getTestContact();
        Account testAccount = frDonorTest.getTestAccount(true);
        Campaign testCampaign = new Campaign(fr_ID__c = '10', Name = 'Test Campaign',
                                             ExpectedRevenue = 123, Description = 'Test', Status = 'Published');
        insert testCampaign;
        Subscription__c subscription = new Subscription__c(Name = 'Test Sub', fr_ID__c = '1234', Supporter__c = testContact.Id);
        insert subscription;

        Map<String, Object> request = getTestRequest();
        request.put('subscriptionId', subscription.fr_ID__c);
        request.put('APEX_TESTS', 'true');
        request.put('opportunityContactMappingDisabled', 'false');
        request.put('donorId', '856');
        frTestUtil.createTestPost(request);

        Test.startTest();
        Sync_Attempt__c syncRecord = new Sync_Attempt__c(
            Request_Body__c = RestContext.request.requestBody.toString(),
            Type__c = frUtil.Entity.DONATION.name(),
            Attempts__c = 1
        );
        frDonation frd = new frDonation(syncRecord);
        frd.setOpportunityStage(new Opportunity(), 'Complete');
        frd.setOpportunityStage(new Opportunity(), 'Failed');
        frd.setOpportunityStage(new Opportunity(), 'Pending');
        frd.setOpportunityStage(new Opportunity(), 'Refunded');
        Test.stopTest();

        frTestUtil.assertNoErrors();
    }

    //
    // Utility methods
    //
    private static void createMapping(String frField, String sfField) {
        insert new frMapping__c(
            Name = frField + sfField,
            fr_Name__c = frField,
            sf_Name__c = sfField,
            Type__c = frDonation.TYPE
        );
    }

    public static Map<String, Object> getTestRequest() {
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
        request.put('softCreditSupporterId', null);
        request.put('paymentMethodType', 'Cash');
        return request;
    }

    public static Opportunity getTestOpp() {
        return new Opportunity(
            CloseDate = Date.today(),
            StageName = 'Closed Won',
            Name = 'Unit Test Opportunity',
            fr_Id__c = '19931107'
        );
    }

    public static SObject getTestGT() {
        SObject o = Schema.getGlobalDescribe().get('gifttransaction').newSObject();
        o.put('Name', 'Unit Test Opportunity');
        o.put('OriginalAmount', 110.11);
        o.put('CheckDate', Date.Today());
        o.put('AcknowledgementDate', System.today());
        o.put('fr_Id__c', '19931107');
        o.put('PaymentMethod', 'Cash');
        return o;
    }

    public static Pledge__c getTestPledge(Contact supporter) {
        return new Pledge__c(
            Supporter__c = supporter.Id,
            Pledge_Amount__c = 500
        );
    }

    public static Pledge__c getTestPledgeAcc(Account supporter) {
        return new Pledge__c(
            Supporter__c = (String) supporter.get('PersonContactId'),
            Supporter_PA__c = supporter.Id,
            Pledge_Amount__c = 500
        );
    }
}