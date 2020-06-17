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
* CREATED: 2016 Funraise Inc - https://funraise.io
* AUTHOR: Jason M. Swenski
*/

public class frDonation extends frModel {
    //Donation statuses
    private static final String COMPLETE = 'Complete';
    private static final String PENDING = 'Pending';
    private static final String REFUNDED = 'Refunded';
    private static final String FAILED = 'Failed';
    
    //Opportunity Contact Role types
    @TestVisible private static final String OPP_ROLE_DONOR = 'Donor';
    @TestVisible private static final String OPP_ROLE_FUNDRAISER = 'Fundraiser';
    @TestVisible private static final String OPP_ROLE_TEAM_CAPTAIN = 'Team Captain';
    @TestVisible private static final String OPP_ROLE_SOFT_CREDIT = 'Soft Credit';
    
    private static final String META_OPP_CONTACT_MAPPING_KEY = 'opportunityContactMappingDisabled';
    private static final String META_CAMPAIGN_MAPPING_KEY = 'campaignMappingDisabled';
    
    public static List<frMapping__c> mappings {
        get {
            if(mappings == null) {
                mappings = [SELECT fr_Name__c, sf_Name__c, Is_Constant__c, Constant_Value__c, Type__c FROM frMapping__c WHERE Type__c = :TYPE ORDER BY CreatedDate];
            }
            return mappings;
        }
        set;
    }
    
    public override List<frMapping__c> getMappings() {
        return mappings;
    }
    public static final String TYPE = 'Donation';
    protected override SObject getObject() {
        return o;
    }
    
    private Opportunity o;
    
    public Opportunity getOpportunity() {
        return o;
    }
    
    public frDonation(Map<String, Object> request) {
        o = new Opportunity();
        super.populateFromRequest(request);
        String funraiseId = String.valueOf(request.get('id'));
        
        String status = String.valueOf(request.get('status'));
        
        if(String.isBlank(o.StageName)) {
            if (status == PENDING) {
                o.StageName = PENDING;
            } else if (status == FAILED || status == REFUNDED) {
                o.StageName = 'Closed Lost';
            } else {
                o.StageName = 'Closed Won';
            }
        }
        
        String supporterFunraiseId = String.valueOf(request.get('donorId'));        
        if (String.isNotBlank(supporterFunraiseId)) {
            List<Contact> contacts = [SELECT Id, AccountId FROM Contact WHERE fr_ID__c = :supporterFunraiseId];
            if (contacts.size() > 0) {
                Contact supporterContact = contacts.get(0);
                o.fr_Donor__c = supporterContact.Id;
                if(frUtil.hasNPSP()){
                    o.put('npsp__Primary_Contact__c', supporterContact.Id);
                    o.AccountId = supporterContact.AccountId;
                }
            } else {
                frUtil.logRelationshipError(frUtil.Entity.DONATION, funraiseId, 
                                            frUtil.Entity.SUPPORTER, supporterFunraiseId);
            }
        }
        
        Boolean campaignMappingDisabled = request.containsKey(META_CAMPAIGN_MAPPING_KEY) ?
            Boolean.valueOf(request.get(META_CAMPAIGN_MAPPING_KEY)): true;
        if(!campaignMappingDisabled) {
            String campaignId = String.valueOf(request.get('campaignGoalId'));
            if (String.isNotBlank(campaignId)) {
                List<Campaign> campaigns = [SELECT Id FROM Campaign WHERE fr_ID__c = :campaignId];
                if (campaigns.size() > 0) {
                    o.CampaignId = campaigns[0].Id;
                } else {
                    frUtil.logRelationshipError(frUtil.Entity.DONATION, funraiseId, 
                                                frUtil.Entity.CAMPAIGN, campaignId);
                }
            }
        }
        
        String subscriptionId = String.valueOf(request.get('subscriptionId'));
        if (String.isNotBlank(subscriptionId)) {
            List<Subscription__c> subscriptions = [SELECT Id FROM Subscription__c WHERE fr_ID__c = :subscriptionId];
            if (subscriptions.size() > 0) {
                o.Subscription__c = subscriptions.get(0).Id;
            } else {
                frUtil.logRelationshipError(frUtil.Entity.DONATION, funraiseId, 
                                            frUtil.Entity.SUBSCRIPTION, subscriptionId);
            }
        }
        Opportunity opp = getOpportunity();
        
        
        Boolean isPledge = Boolean.valueOf(request.get('pledge'));
        if(!isPledge) {
            Pledge__c pledge = frPledge.findActive(opp.fr_Donor__c);
            opp.Funraise_Pledge__c = pledge != null ? pledge.Id : null;
        }
        
        try {
            Database.upsert(opp, Opportunity.Fields.fr_Id__c, true);
        } catch (Exception ex) {
            frUtil.logException(frUtil.Entity.DONATION, funraiseId, ex);
        }
        
        if(isPledge) {
            frPledge.create(opp);
        }
    }
    
    public void createOpportunityMapping(Map<String, Object> request) {
        Boolean mappingDisabled = request.containsKey(META_OPP_CONTACT_MAPPING_KEY) ?
            Boolean.valueOf(request.get(META_OPP_CONTACT_MAPPING_KEY)): true;
        if(mappingDisabled) {
            return;
        }
        
        String funraiseId = String.valueOf(request.get('id'));
        String supporterId = String.valueOf(request.get('donorId'));
        
        Set<String> relatedSupporterFunraiseIds = new Set<String>{supporterId};
            
        String fundraiserId = request.containsKey('fundraiserId') ? String.valueOf(request.get('fundraiserId')) : null;
        if(String.isNotBlank(fundraiserId)) {
            relatedSupporterFunraiseIds.add(fundraiserId);
        }
        String teamCaptainId = request.containsKey('teamCaptainId') ? String.valueOf(request.get('teamCaptainId')) : null;
        if(String.isNotBlank(teamCaptainId)) {
            relatedSupporterFunraiseIds.add(teamCaptainId);
        }
        String softCreditSupporterId = request.containsKey('softCreditSupporterId') ? String.valueOf(request.get('softCreditSupporterId')) : null;
        if(String.isNotBlank(softCreditSupporterId)) {
            relatedSupporterFunraiseIds.add(softCreditSupporterId);
        }
        
        Map<String, Contact> relatedContacts = new Map<String, Contact>();
        for(Contact relatedContact : [SELECT Id, fr_Id__c, 
                                      (SELECT Id, Role, ContactId FROM OpportunityContactRoles WHERE OpportunityId = :getOpportunityId()) 
                                      from Contact WHERE fr_Id__c IN :relatedSupporterFunraiseIds]) {
                                          relatedContacts.put(relatedContact.fr_Id__c, relatedContact);
                                      }
        
        List<OpportunityContactRole> newContactRoles = new List<OpportunityContactRole>();
        OpportunityContactRole donorRole = createRole(OPP_ROLE_DONOR, supporterId, relatedContacts, funraiseId);
        if(donorRole != null) {
            newContactRoles.add(donorRole);
        }
        
        OpportunityContactRole fundraiserRole = createRole(OPP_ROLE_FUNDRAISER, fundraiserId, relatedContacts, funraiseId);
        if(fundraiserRole != null) {
            newContactRoles.add(fundraiserRole);
        }
        
        OpportunityContactRole teamCaptainRole = createRole(OPP_ROLE_TEAM_CAPTAIN, teamCaptainId, relatedContacts, funraiseId);
        if(teamCaptainRole != null) {
            newContactRoles.add(teamCaptainRole);
        }
        
        OpportunityContactRole softCreditRole = createRole(OPP_ROLE_SOFT_CREDIT, softCreditSupporterId, relatedContacts, funraiseId);
        if(softCreditRole != null) {
            newContactRoles.add(softCreditRole);
        }
        
        try {
            insert newContactRoles;
        } catch (Exception ex) {
            frUtil.logException(frUtil.Entity.DONATION, funraiseId, ex);
        }
    }
    
    private OpportunityContactRole createRole(String role, String funraiseSupporterId, Map<String, Contact> contactsByFunraiseId, String funraiseDonationId) {
        if(String.isBlank(funraiseSupporterId)) {
            return null;
        }
        if(!contactsByFunraiseId.containsKey(funraiseSupporterId)) {
            frUtil.logRelationshipError(frUtil.Entity.DONATION, funraiseDonationId, 
                                        frUtil.Entity.SUPPORTER, funraiseSupporterId,
                                        'Opportunity Contact Role: '+ role);
            return null;
        }
        
        Contact supporter = contactsByFunraiseId.get(funraiseSupporterId);
        Set<String> existingRoles = new Set<String>();
        for(OpportunityContactRole contactRole : supporter.OpportunityContactRoles) {
            existingRoles.add(contactRole.Role);
        }
        if(!existingRoles.contains(role)) {
            OpportunityContactRole newRole = new OpportunityContactRole();
            newRole.ContactId = supporter.Id;
            newRole.OpportunityId = getOpportunityId();
            newRole.Role = role;
            return newRole;
        }
        return null;
    }
    
    public Boolean hasDonor() {
        return getOpportunity() != null && getOpportunity().fr_Donor__c != null;
    }
    
    public String getOpportunityId() {
        return getOpportunity() != null ? getOpportunity().Id : null;
    }
}