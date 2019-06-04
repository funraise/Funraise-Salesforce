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
    
    private String opportunityId;
    private String donorId;
    private String sfDonorId;
    private Opportunity o;
    
    public frDonation() {
        this.o = new Opportunity();
    }
    
    public Opportunity getOpportunity() {
        o.fr_Donor__c = getSfDonorId();
        return o;
    }
    
    public override void populateFromRequest(Map<String, Object> request) {
        super.populateFromRequest(request);
        this.setDonorId(String.valueOf(request.get('donorId')));
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
        
        String campaignId = String.valueOf(request.get('campaignGoalId'));
        if (campaignId != '' && campaignId != null) {
            Campaign[] campaign = [SELECT Id FROM Campaign WHERE fr_ID__c = :campaignId];
            // Make sure a campaign was found before we assign it
            if (campaign.size() > 0) {
                o.CampaignId = campaign[0].Id;
            }
        }
        
        if(hasNonProfitSuccessPackage()){
            List<Contact> contacts = Database.query('select AccountId from Contact where fr_ID__c = :donorId');
            if(contacts.size() > 0){
                Contact primaryContact = contacts.get(0);
                if(o.get('npsp__Primary_Contact__c') == null){
                    o.put('npsp__Primary_Contact__c', primaryContact.Id);
                }
                if(o.AccountId == null){
                    o.AccountId=primaryContact.AccountId;
                }
            }
        }
    }
    
    private Boolean hasNonProfitSuccessPackage(){
        try {
            return UserInfo.isCurrentUserLicensed('npsp');
        } catch (TypeException te) {
            return false;
        }
    }
    
    public static frDonation create(Map<String, Object> request) {
        frDonation donation = new frDonation();
        donation.populateFromRequest(request);
        return donation;
    }
    
    public Boolean save() {
        Boolean isSuccess = false;
        try {
            Opportunity opp = getOpportunity();
            
            Database.upsert(opp,Opportunity.Fields.fr_Id__c,true);
            setOpportunityId(opp.Id);
            isSuccess = true;
        } catch (Exception ex) {
            handleException(ex);
            isSuccess = false;
        }
        flushLogs();
        return isSuccess;
    }
    
    public void createOpportunityMapping(Map<String, Object> request) {
        Boolean mappingDisabled = request.containsKey('opportunityContactMappingDisabled') ?
            Boolean.valueOf(request.get('opportunityContactMappingDisabled')): true;
        if (!mappingDisabled) {
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
            Map<String, Contact> relatedContacts = new Map<String, Contact>();
            for(Contact relatedContact : [SELECT Id, fr_Id__c, 
                                          (SELECT Id, Role, ContactId FROM OpportunityContactRoles WHERE OpportunityId = :getOpportunityId()) 
                                          from Contact WHERE fr_Id__c IN :relatedSupporterFunraiseIds]) {
                relatedContacts.put(relatedContact.fr_Id__c, relatedContact);
            }
            
            List<OpportunityContactRole> newContactRoles = new List<OpportunityContactRole>();
            OpportunityContactRole donorRole = createRole(relatedContacts.get(supporterId), OPP_ROLE_DONOR);
            if(donorRole != null) newContactRoles.add(donorRole);
            
            if(String.isNotBlank(fundraiserId)) {
                if(!relatedContacts.containsKey(fundraiserId)) {
                    insert new Error__c(Error__c =
                                        'Failed to find related record: Contact with funraise id ' 
                                        + fundraiserId+ 
                                        ' for opportunity contact role '+ OPP_ROLE_FUNDRAISER +' for opportunity with funraise id ' 
                                        + funraiseId);
                } else {
                    OpportunityContactRole fundraiserRole = createRole(relatedContacts.get(fundraiserId), OPP_ROLE_FUNDRAISER);
                    if(fundraiserRole != null) newContactRoles.add(fundraiserRole);
                }
            }
            if(String.isNotBlank(teamCaptainId)) {
                if(!relatedContacts.containsKey(teamCaptainId)) {
                    insert new Error__c(Error__c =
                                        'Failed to find related record: Contact with funraise id ' 
                                        + teamCaptainId+ 
                                        ' for opportunity contact role '+ OPP_ROLE_TEAM_CAPTAIN +' for opportunity with funraise id ' 
                                        + funraiseId);
                } else {
                    OpportunityContactRole captainRole = createRole(relatedContacts.get(teamCaptainId), OPP_ROLE_TEAM_CAPTAIN);
                    if(captainRole != null) newContactRoles.add(captainRole);
                }
            }
            
            insert newContactRoles;
        }
    }
    
    private OpportunityContactRole createRole(Contact supporter, String role) {
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
    
    public String getDonorId() {
        return this.donorId;
    }
    
    public void setDonorId(String donorId) {
        this.donorId = donorId;
    }
    
    public String getOpportunityId() {
        return opportunityId;
    }
    
    public void setOpportunityId(String opportunityId) {
        this.opportunityId = opportunityId;
    }
    
    public String getSfDonorId() {
        return sfDonorId;
    }
    
    public void setSfDonorId(String sfDonorId) {
        this.sfDonorId = sfDonorId;
    }
}