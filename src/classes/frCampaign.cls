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
* AUTHOR: Jordan Speer
*/

public class frCampaign {
    
    public frCampaign(Map<String, Object> request) {
        if (Boolean.valueOf(request.get('deleted'))) {
            deleteCampaign(request);
        } else {
            create(request);
        }
    }
    
    public void deleteCampaign(Map<String, Object> request) {
        String goalId = String.valueOf(request.get('goalId'));
        try {
            List<Campaign> campaigns = [SELECT Id, fr_ID__c, ParentId, 
                                 (SELECT Id, fr_ID__c, ParentId from ChildCampaigns)
                                 from Campaign where fr_ID__c = :goalId];
            if(campaigns.size() == 0) {return;}
            Campaign campaignToDelete = campaigns.get(0);
            if (campaignToDelete.ChildCampaigns.size() > 0) {
                if(String.isNotBlank(campaignToDelete.ParentId)) {
                    for (Campaign childCampaign : campaignToDelete.ChildCampaigns) {
                        childCampaign.parentId = campaignToDelete.ParentId;
                    }
                    update campaignToDelete.ChildCampaigns;
                } else {
                    delete campaignToDelete.ChildCampaigns;
                }
            }
            delete campaignToDelete;
            return;
        } catch (DMLException e) {
            frUtil.logException(frUtil.Entity.CAMPAIGN, goalId, e);
        }
    }
    
    public void create(Map<String, Object> request) {
        String goalId = String.valueOf(request.get('goalId'));
        
        Campaign newCampaign = new Campaign();
        newCampaign.Name = String.valueOf(request.get('name'));
        newCampaign.Description = String.valueOf(request.get('reason'));
        newCampaign.Status = String.valueOf(request.get('status'));
        newCampaign.ExpectedRevenue = Decimal.valueOf(String.valueOf(request.get('goalAmount')));
        newCampaign.fr_ID__c = goalId;
        
        String parentId = String.valueOf(request.get('parentGoalId'));
        if (String.isNotBlank(parentId)) {
            List<Campaign> parentCampaigns = [SELECT Id, fr_ID__c from Campaign where fr_ID__c = :parentId];
            if(parentCampaigns.size() > 0) {
                newCampaign.ParentId = parentCampaigns.get(0).Id;                
            } else {
                frUtil.logRelationshipError(frUtil.Entity.CAMPAIGN, goalId, 
                                            frUtil.Entity.CAMPAIGN, parentId);
            }
        }
        try {
            Database.upsert(newCampaign, Campaign.Field.fr_ID__c, true);
        } catch (DMLException e) {
            frUtil.logException(frUtil.Entity.CAMPAIGN, goalId, e);
			return;
        }
        
        String supporterFunraiseId = String.valueOf(request.get('supporterId'));        
        if (String.isNotBlank(supporterFunraiseId)) {
            List<Contact> contacts = [SELECT Id, AccountId, (SELECT Id FROM CampaignMembers WHERE CampaignId = :newCampaign.Id) 
                                      FROM Contact WHERE fr_ID__c = :supporterFunraiseId];
            if (contacts.size() > 0) {
                Contact supporterContact = contacts.get(0);
                if(supporterContact.CampaignMembers.size() == 0) {
                    CampaignMember fundraiserMember = new CampaignMember(
                        CampaignId = newCampaign.Id,
                        ContactId = supporterContact.Id
                    );
                    try {
                        insert fundraiserMember;
                    } catch (DMLException ex) {
                        frUtil.logException(frUtil.Entity.CAMPAIGN, goalId, ex);
                        return;
                    }
                }
            } else {
                frUtil.logRelationshipError(frUtil.Entity.CAMPAIGN, goalId, 
                                            frUtil.Entity.SUPPORTER, supporterFunraiseId);
            }
        }
    }
}